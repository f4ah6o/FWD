///|
/// HTTP adapter v5.2 draft (retention multi-axis, non-wall-clock).

///|
pub(all) struct ApiRequest {
  http_method : String
  path : String
  query : Map[String, String]
  body : String?
}

///|
pub(all) struct ApiResponse {
  status : Int
  headers : Map[String, String]
  body : String
}

fn response_json(status : Int, body : String) -> ApiResponse {
  let headers : Map[String, String] = Map::new()
  headers["content-type"] = "application/json"
  { status, headers, body }
}

fn response_jsonl(status : Int, body : String) -> ApiResponse {
  let headers : Map[String, String] = Map::new()
  headers["content-type"] = "application/jsonl"
  { status, headers, body }
}

fn response_csv(status : Int, body : String) -> ApiResponse {
  let headers : Map[String, String] = Map::new()
  headers["content-type"] = "text/csv"
  { status, headers, body }
}

fn error_envelope_json(reason : @core.Reason) -> String {
  let obj : Map[String, Json] = Map::new()
  obj["error"] = @compiler.reason_json(reason)
  Json::object(obj).stringify(indent=2)
}

fn error_with_retention_json(
  reason : @core.Reason,
  details : @export_job_v5_2.RetentionDetailsV52,
  endpoint : String?,
) -> String {
  let obj : Map[String, Json] = Map::new()
  obj["error"] = @compiler.reason_json(reason)
  let retention : Map[String, Json] = Map::new()
  retention["visibility"] = Json::string(details.visibility)
  retention["combine"] = Json::string(details.combine)
  let failed : Array[Json] = []
  for axis in details.failed_axes {
    failed.push(Json::object({
      "axis": Json::string(axis.axis),
      "rule": Json::string(axis.rule),
      "expected": Json::number(axis.expected.to_double()),
      "observed": Json::number(axis.observed.to_double()),
      "reason": Json::string(axis.reason),
    }))
  }
  retention["failedAxes"] = Json::array(failed)
  match endpoint {
    Some(name) => retention["endpoint"] = Json::string(name)
    None => ()
  }
  obj["retentionDetails"] = Json::object(retention)
  Json::object(obj).stringify(indent=2)
}

fn invalid_query_reason(message : String) -> @core.Reason {
  @core.Reason::with_context(
    "QUERY_INVALID",
    message,
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Check query parameters"),
    ],
  )
}

fn missing_query_reason(name : String) -> @core.Reason {
  @core.Reason::with_context(
    "QUERY_MISSING",
    "missing query: " + name,
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Provide query '" + name + "'"),
    ],
  )
}

fn job_not_found_reason(job_id : String) -> @core.Reason {
  @core.Reason::with_context(
    "JOB_NOT_FOUND",
    "job not found: " + job_id,
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Check job id"),
    ],
  )
}

fn job_not_ready_reason(job_id : String) -> @core.Reason {
  @core.Reason::with_context(
    "JOB_NOT_READY",
    "job not ready: " + job_id,
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Wait for job to complete"),
    ],
  )
}

fn job_canceled_reason(job_id : String) -> @core.Reason {
  @core.Reason::with_context(
    "JOB_CANCELED",
    "job canceled: " + job_id,
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Job was canceled"),
    ],
  )
}

fn job_hidden_reason(job_id : String) -> @core.Reason {
  @core.Reason::with_context(
    "JOB_EXPIRED",
    "job hidden by retention: " + job_id,
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Job retention policy hidden"),
    ],
  )
}

fn parse_format(value : String) -> @export_job_v5_2.ResultFormat? {
  if value == "jsonl" {
    Some(@export_job_v5_2.ResultFormat::Jsonl)
  } else if value == "csv" {
    Some(@export_job_v5_2.ResultFormat::Csv)
  } else {
    None
  }
}

fn extract_body_json(body : String) -> Result[Map[String, Json], @core.Reason] {
  let parsed : Result[Json, @json.ParseError] = try? @json.parse(body)
  let value = match parsed {
    Ok(v) => v
    Err(err) => return Err(invalid_query_reason("input json parse error: " + err.to_string()))
  }
  match value {
    Object(m) => Ok(m)
    _ => Err(invalid_query_reason("input json must be an object"))
  }
}

fn extract_string_field(obj : Map[String, Json], name : String) -> Result[String, @core.Reason] {
  match obj.get(name) {
    Some(String(value)) => Ok(value)
    Some(_) => Err(invalid_query_reason("field must be string: " + name))
    None => Err(missing_query_reason(name))
  }
}

fn parse_axis_item(value : Json) -> Result[@export_job_v5_2.RetentionAxisConditionV52, @core.Reason] {
  let obj = match value {
    Object(m) => m
    _ => return Err(invalid_query_reason("retentionPolicy.axes entries must be objects"))
  }
  let type_value = match obj.get("type") {
    Some(String(v)) => v
    Some(_) => return Err(invalid_query_reason("retentionPolicy.axes.type must be string"))
    None => return Err(missing_query_reason("retentionPolicy.axes.type"))
  }
  let number_value = match obj.get("value") {
    Some(Number(v, ..)) => v.to_int()
    Some(_) => return Err(invalid_query_reason("retentionPolicy.axes.value must be number"))
    None => return Err(missing_query_reason("retentionPolicy.axes.value"))
  }
  if type_value == "poll_count_max" {
    Ok(@export_job_v5_2.RetentionAxisConditionV52::PollCountMax(number_value))
  } else if type_value == "generation_min" {
    Ok(@export_job_v5_2.RetentionAxisConditionV52::GenerationMin(number_value))
  } else {
    Err(invalid_query_reason("unknown retentionPolicy.axes.type: " + type_value))
  }
}

fn default_policy_job() -> @export_job_v5_2.RetentionPolicyV52 {
  {
    combine: @export_job_v5_2.RetentionCombineV52::All,
    axes: [@export_job_v5_2.RetentionAxisConditionV52::PollCountMax(3)],
  }
}

fn default_policy_batch() -> @export_job_v5_2.RetentionPolicyV52 {
  {
    combine: @export_job_v5_2.RetentionCombineV52::All,
    axes: [@export_job_v5_2.RetentionAxisConditionV52::PollCountMax(@export_job_batch_v5_2.default_poll_max)],
  }
}

fn parse_policy_optional(obj : Map[String, Json], default_policy : @export_job_v5_2.RetentionPolicyV52) -> Result[@export_job_v5_2.RetentionPolicyV52, @core.Reason] {
  match obj.get("retentionPolicy") {
    None => Ok(default_policy)
    Some(value) => {
      let policy_obj = match value {
        Object(m) => m
        _ => return Err(invalid_query_reason("retentionPolicy must be object"))
      }
      match policy_obj.get("combine") {
        Some(String("all")) => ()
        Some(String(_)) => return Err(invalid_query_reason("retentionPolicy.combine must be 'all'"))
        Some(_) => return Err(invalid_query_reason("retentionPolicy.combine must be string"))
        None => return Err(missing_query_reason("retentionPolicy.combine"))
      }
      let axes_json = match policy_obj.get("axes") {
        Some(Array(items)) => items
        Some(_) => return Err(invalid_query_reason("retentionPolicy.axes must be array"))
        None => return Err(missing_query_reason("retentionPolicy.axes"))
      }
      let axes : Array[@export_job_v5_2.RetentionAxisConditionV52] = []
      for item in axes_json {
        let axis = match parse_axis_item(item) {
          Ok(v) => v
          Err(reason) => return Err(reason)
        }
        axes.push(axis)
      }
      Ok({
        combine: @export_job_v5_2.RetentionCombineV52::All,
        axes,
      })
    }
  }
}

fn status_string(status : @export_job_v5_2.JobStatus) -> String {
  match status {
    @export_job_v5_2.JobStatus::Queued => "queued"
    @export_job_v5_2.JobStatus::Running => "running"
    @export_job_v5_2.JobStatus::Done => "done"
    @export_job_v5_2.JobStatus::Failed => "failed"
    @export_job_v5_2.JobStatus::Canceled => "canceled"
    @export_job_v5_2.JobStatus::Expired => "expired"
  }
}

fn reason_json(reason : @export_job_v5.ReasonV1) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["reasonVersion"] = Json::number(1)
  obj["code"] = Json::string(match reason.code {
    @export_job_v5.ReasonCode::QueryMissing => "QUERY_MISSING"
    @export_job_v5.ReasonCode::QueryInvalid => "QUERY_INVALID"
    @export_job_v5.ReasonCode::JobNotFound => "JOB_NOT_FOUND"
    @export_job_v5.ReasonCode::JobNotReady => "JOB_NOT_READY"
    @export_job_v5.ReasonCode::JobCanceled => "JOB_CANCELED"
    @export_job_v5.ReasonCode::JobExpired => "JOB_EXPIRED"
    @export_job_v5.ReasonCode::PolicyDenied => "POLICY_DENIED"
  })
  obj["level"] = Json::string(match reason.level {
    @export_job_v5.ReasonLevel::Error => "error"
    @export_job_v5.ReasonLevel::Warn => "warn"
    @export_job_v5.ReasonLevel::Info => "info"
  })
  obj["target"] = Json::string(reason.target)
  obj["message"] = Json::string(reason.message)
  match reason.hint {
    Some(value) => obj["hint"] = Json::string(value)
    None => ()
  }
  Json::object(obj)
}

fn job_json(job : @export_job_v5_2.JobRecord) -> String {
  let obj : Map[String, Json] = Map::new()
  obj["jobVersion"] = Json::string("5.2")
  obj["jobId"] = Json::string(job.id.value)
  obj["status"] = Json::string(status_string(job.status))
  obj["progress"] = Json::object({
    "processed": Json::number(job.progress.processed.to_double()),
    "total": Json::number(job.progress.total.to_double()),
  })
  obj["generation"] = Json::number(job.generation.to_double())
  match job.status {
    @export_job_v5_2.JobStatus::Done => obj["downloadUrl"] = Json::string("/v5.2/export/jobs/" + job.id.value + "/result")
    _ => ()
  }
  if job.reasons.length() > 0 {
    let reasons : Array[Json] = []
    for reason in job.reasons {
      reasons.push(reason_json(reason))
    }
    obj["reasons"] = Json::array(reasons)
  }
  Json::object(obj).stringify(indent=2)
}

fn batch_job_json(batch : @export_job_batch_v5_2.BatchJobRecord) -> String {
  let obj : Map[String, Json] = Map::new()
  obj["jobVersion"] = Json::string("5.2")
  obj["jobId"] = Json::string(batch.id)
  obj["status"] = Json::string(status_string(batch.status))
  obj["progress"] = Json::object({
    "processed": Json::number(batch.progress.processed.to_double()),
    "total": Json::number(batch.progress.total.to_double()),
  })
  obj["generation"] = Json::number(batch.generation.to_double())
  let child_ids : Array[Json] = []
  for child_id in batch.child_ids {
    child_ids.push(Json::string(child_id))
  }
  obj["childIds"] = Json::array(child_ids)
  match batch.status {
    @export_job_v5_2.JobStatus::Done => obj["downloadUrl"] = Json::string("/v5.2/export/batch/jobs/" + batch.id + "/result")
    _ => ()
  }
  if batch.reasons.length() > 0 {
    let reasons : Array[Json] = []
    for reason in batch.reasons {
      reasons.push(reason_json(reason))
    }
    obj["reasons"] = Json::array(reasons)
  }
  Json::object(obj).stringify(indent=2)
}

fn result_body_jsonl() -> String {
  "{\"type\":\"total\",\"window\":{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12},\"counts\":{\"ok\":1,\"failed\":1,\"blocked\":0,\"denied\":1}}\n"
}

fn result_body_csv() -> String {
  "type,entityId,fromLogicalTime,toLogicalTime,kind,ok,failed,blocked,denied\n"
}

fn batch_result_body_jsonl(batch : @export_job_batch_v5_2.BatchJobRecord) -> String {
  let sb = StringBuilder::new()
  for spec in batch.child_specs {
    sb.write_string("{\"type\":\"total\",\"window\":{\"entityId\":\"")
    sb.write_string(spec.entity_id)
    sb.write_string("\",\"fromLogicalTime\":")
    sb.write_string(spec.from_logical_time.to_string())
    sb.write_string(",\"toLogicalTime\":")
    sb.write_string(spec.to_logical_time.to_string())
    sb.write_string("},\"counts\":{\"ok\":1,\"failed\":1,\"blocked\":0,\"denied\":1}}")
    sb.write_string("\n")
  }
  sb.to_string()
}

fn batch_result_body_csv(batch : @export_job_batch_v5_2.BatchJobRecord) -> String {
  let sb = StringBuilder::new()
  sb.write_string("type,entityId,fromLogicalTime,toLogicalTime,kind,ok,failed,blocked,denied\n")
  for spec in batch.child_specs {
    sb.write_string("total,")
    sb.write_string(spec.entity_id)
    sb.write_string(",")
    sb.write_string(spec.from_logical_time.to_string())
    sb.write_string(",")
    sb.write_string(spec.to_logical_time.to_string())
    sb.write_string(",total,1,1,0,1\n")
  }
  sb.to_string()
}

fn evaluate_job_visibility(job : @export_job_v5_2.JobRecord, endpoint : String?) -> ApiResponse? {
  let outcome = @retention_v5_2.evaluate_retention_v52(
    job.retention_policy,
    { poll_count: job.poll_count, generation: job.generation },
  )
  match outcome {
    @export_job_v5_2.RetentionOutcomeV52::Visible => None
    @export_job_v5_2.RetentionOutcomeV52::Hidden(failed) => {
      let details = @retention_v5_2.retention_details(job.retention_policy, failed)
      Some(response_json(404, error_with_retention_json(job_hidden_reason(job.id.value), details, endpoint)))
    }
  }
}

fn evaluate_batch_visibility(batch : @export_job_batch_v5_2.BatchJobRecord, endpoint : String?) -> ApiResponse? {
  let outcome = @retention_v5_2.evaluate_retention_v52(
    batch.retention_policy,
    { poll_count: batch.poll_count, generation: batch.generation },
  )
  match outcome {
    @export_job_v5_2.RetentionOutcomeV52::Visible => None
    @export_job_v5_2.RetentionOutcomeV52::Hidden(failed) => {
      let details = @retention_v5_2.retention_details(batch.retention_policy, failed)
      Some(response_json(404, error_with_retention_json(job_hidden_reason(batch.id), details, endpoint)))
    }
  }
}

fn parse_batch_child_specs(obj : Map[String, Json]) -> Result[Array[@export_job_batch_v5_2.BatchChildSpec], @core.Reason] {
  match obj.get("jobs") {
    Some(Array(items)) => {
      if items.length() == 0 {
        return Err(invalid_query_reason("jobs must be non-empty"))
      }
      let specs : Array[@export_job_batch_v5_2.BatchChildSpec] = []
      for item in items {
        let entry = match item {
          Object(m) => m
          _ => return Err(invalid_query_reason("jobs entries must be objects"))
        }
        let entity_id = match extract_string_field(entry, "entityId") {
          Ok(v) => v
          Err(reason) => return Err(reason)
        }
        let from_value = match entry.get("fromLogicalTime") {
          Some(Number(v, ..)) => v.to_int()
          Some(_) => return Err(invalid_query_reason("fromLogicalTime must be number"))
          None => return Err(missing_query_reason("fromLogicalTime"))
        }
        let to_value = match entry.get("toLogicalTime") {
          Some(Number(v, ..)) => v.to_int()
          Some(_) => return Err(invalid_query_reason("toLogicalTime must be number"))
          None => return Err(missing_query_reason("toLogicalTime"))
        }
        specs.push({ entity_id, from_logical_time: from_value, to_logical_time: to_value })
      }
      Ok(specs)
    }
    Some(_) => Err(invalid_query_reason("jobs must be array"))
    None => Err(missing_query_reason("jobs"))
  }
}

fn substring_from(value : String, start : Int) -> String {
  let sb = StringBuilder::new()
  for i in start..<value.length() {
    let ch = value[i].to_int()
    sb.write_char(Int::unsafe_to_char(ch))
  }
  sb.to_string()
}

fn substring_range(value : String, start : Int, end : Int) -> String {
  let sb = StringBuilder::new()
  let limit = if end < value.length() { end } else { value.length() }
  for i in start..<limit {
    let ch = value[i].to_int()
    sb.write_char(Int::unsafe_to_char(ch))
  }
  sb.to_string()
}

///|
pub fn handle_request(req : ApiRequest) -> ApiResponse {

  if req.http_method == "POST" && req.path == "/v5.2/export/jobs" {
    let body = match req.body {
      Some(value) => value
      None => return response_json(400, error_envelope_json(invalid_query_reason("missing body")))
    }
    let obj = match extract_body_json(body) {
      Ok(value) => value
      Err(reason) => return response_json(400, error_envelope_json(reason))
    }
    let format_value = match extract_string_field(obj, "format") {
      Ok(v) => v
      Err(reason) => return response_json(400, error_envelope_json(reason))
    }
    let format = match parse_format(format_value) {
      Some(v) => v
      None => return response_json(400, error_envelope_json(invalid_query_reason("invalid format")))
    }
    let policy = match parse_policy_optional(obj, default_policy_job()) {
      Ok(v) => v
      Err(reason) => return response_json(400, error_envelope_json(reason))
    }
    let job = @job_store_v5_2.create_job(format, policy)
    return response_json(200, job_json(job))
  }

  if req.http_method == "POST" && req.path == "/v5.2/export/batch/jobs" {
    let body = match req.body {
      Some(value) => value
      None => return response_json(400, error_envelope_json(invalid_query_reason("missing body")))
    }
    let obj = match extract_body_json(body) {
      Ok(value) => value
      Err(reason) => return response_json(400, error_envelope_json(reason))
    }
    let format_value = match extract_string_field(obj, "format") {
      Ok(v) => v
      Err(reason) => return response_json(400, error_envelope_json(reason))
    }
    let format = match parse_format(format_value) {
      Some(v) => v
      None => return response_json(400, error_envelope_json(invalid_query_reason("invalid format")))
    }
    let specs = match parse_batch_child_specs(obj) {
      Ok(v) => v
      Err(reason) => return response_json(400, error_envelope_json(reason))
    }
    let policy = match parse_policy_optional(obj, default_policy_batch()) {
      Ok(v) => v
      Err(reason) => return response_json(400, error_envelope_json(reason))
    }
    let batch = @export_job_batch_v5_2.create_batch(format, policy, specs)
    return response_json(200, batch_job_json(batch))
  }

  let batch_prefix = "/v5.2/export/batch/jobs/"
  if req.path.has_prefix(batch_prefix) {
    let suffix = substring_from(req.path, batch_prefix.length())
    if req.http_method == "POST" && suffix.has_suffix("/cancel") {
      let batch_id = substring_range(suffix, 0, suffix.length() - "/cancel".length())
      if batch_id.length() == 0 {
        return response_json(404, error_envelope_json(job_not_found_reason(batch_id)))
      }
      return match @export_job_batch_v5_2.cancel_batch(batch_id) {
        Some(batch) => response_json(200, batch_job_json(batch))
        None => response_json(404, error_envelope_json(job_not_found_reason(batch_id)))
      }
    }
    if req.http_method == "POST" && suffix.has_suffix("/step") {
      let batch_id = substring_range(suffix, 0, suffix.length() - "/step".length())
      if batch_id.length() == 0 {
        return response_json(404, error_envelope_json(job_not_found_reason(batch_id)))
      }
      return match @export_job_batch_v5_2.step_batch(batch_id) {
        Some(batch) => response_json(200, batch_job_json(batch))
        None => response_json(404, error_envelope_json(job_not_found_reason(batch_id)))
      }
    }
    if req.http_method == "GET" && suffix.has_suffix("/result") {
      let batch_id = substring_range(suffix, 0, suffix.length() - "/result".length())
      if batch_id.length() == 0 {
        return response_json(404, error_envelope_json(job_not_found_reason(batch_id)))
      }
      return match @export_job_batch_v5_2.get_batch(batch_id) {
        Some(batch) => {
          match evaluate_batch_visibility(batch, Some("result")) {
            Some(res) => res
            None => match batch.status {
              @export_job_v5_2.JobStatus::Done => match batch.format {
                @export_job_v5_2.ResultFormat::Jsonl => response_jsonl(200, batch_result_body_jsonl(batch))
                @export_job_v5_2.ResultFormat::Csv => response_csv(200, batch_result_body_csv(batch))
              }
              @export_job_v5_2.JobStatus::Canceled => response_json(409, error_envelope_json(job_canceled_reason(batch_id)))
              _ => response_json(409, error_envelope_json(job_not_ready_reason(batch_id)))
            }
          }
        }
        None => response_json(404, error_envelope_json(job_not_found_reason(batch_id)))
      }
    }
    if req.http_method == "GET" {
      let batch_id = suffix
      if batch_id.length() == 0 {
        return response_json(404, error_envelope_json(job_not_found_reason(batch_id)))
      }
      return match @export_job_batch_v5_2.get_batch(batch_id) {
        Some(batch) => {
          match evaluate_batch_visibility(batch, None) {
            Some(res) => res
            None => response_json(200, batch_job_json(batch))
          }
        }
        None => response_json(404, error_envelope_json(job_not_found_reason(batch_id)))
      }
    }
  }

  let prefix = "/v5.2/export/jobs/"
  if req.path.has_prefix(prefix) {
    let suffix = substring_from(req.path, prefix.length())
    if req.http_method == "POST" && suffix.has_suffix("/cancel") {
      let job_id = substring_range(suffix, 0, suffix.length() - "/cancel".length())
      if job_id.length() == 0 {
        return response_json(404, error_envelope_json(job_not_found_reason(job_id)))
      }
      return match @job_store_v5_2.cancel_job(job_id) {
        Some(job) => response_json(200, job_json(job))
        None => response_json(404, error_envelope_json(job_not_found_reason(job_id)))
      }
    }
    if req.http_method == "POST" && suffix.has_suffix("/step") {
      let job_id = substring_range(suffix, 0, suffix.length() - "/step".length())
      if job_id.length() == 0 {
        return response_json(404, error_envelope_json(job_not_found_reason(job_id)))
      }
      return match @job_store_v5_2.step_job(job_id) {
        Some(job) => response_json(200, job_json(job))
        None => response_json(404, error_envelope_json(job_not_found_reason(job_id)))
      }
    }
    if req.http_method == "GET" && suffix.has_suffix("/result") {
      let job_id = substring_range(suffix, 0, suffix.length() - "/result".length())
      if job_id.length() == 0 {
        return response_json(404, error_envelope_json(job_not_found_reason(job_id)))
      }
      return match @job_store_v5_2.get_job(job_id) {
        Some(job) => {
          match evaluate_job_visibility(job, Some("result")) {
            Some(res) => res
            None => match job.status {
              @export_job_v5_2.JobStatus::Done => match job.format {
                @export_job_v5_2.ResultFormat::Jsonl => response_jsonl(200, result_body_jsonl())
                @export_job_v5_2.ResultFormat::Csv => response_csv(200, result_body_csv())
              }
              @export_job_v5_2.JobStatus::Canceled => response_json(409, error_envelope_json(job_canceled_reason(job_id)))
              _ => response_json(409, error_envelope_json(job_not_ready_reason(job_id)))
            }
          }
        }
        None => response_json(404, error_envelope_json(job_not_found_reason(job_id)))
      }
    }
    if req.http_method == "GET" {
      let job_id = suffix
      if job_id.length() == 0 {
        return response_json(404, error_envelope_json(job_not_found_reason(job_id)))
      }
      return match @job_store_v5_2.get_job(job_id) {
        Some(job) => {
          match evaluate_job_visibility(job, None) {
            Some(res) => res
            None => response_json(200, job_json(job))
          }
        }
        None => response_json(404, error_envelope_json(job_not_found_reason(job_id)))
      }
    }
  }

  response_json(404, error_envelope_json(job_not_found_reason("path")))
}
