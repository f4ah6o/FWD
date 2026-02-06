///|
/// HTTP adapter v4.6 (async export jobs).

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

///|
fn response_json(status : Int, body : String) -> ApiResponse {
  let headers : Map[String, String] = Map::new()
  headers["content-type"] = "application/json"
  { status, headers, body }
}

///|
fn response_jsonl(status : Int, body : String) -> ApiResponse {
  let headers : Map[String, String] = Map::new()
  headers["content-type"] = "application/jsonl"
  { status, headers, body }
}

///|
fn response_jsonl_with_cursor(status : Int, body : String, next_cursor : String?) -> ApiResponse {
  let headers : Map[String, String] = Map::new()
  headers["content-type"] = "application/jsonl"
  match next_cursor {
    Some(value) => headers["x-next-cursor"] = value
    None => ()
  }
  { status, headers, body }
}

///|
fn response_csv(status : Int, body : String) -> ApiResponse {
  let headers : Map[String, String] = Map::new()
  headers["content-type"] = "text/csv"
  { status, headers, body }
}

///|
fn error_envelope_json(reason : @core.Reason) -> String {
  let obj : Map[String, Json] = Map::new()
  obj["error"] = @compiler.reason_json(reason)
  Json::object(obj).stringify(indent=2)
}

///|
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

///|
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

///|
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

fn extract_optional_string(obj : Map[String, Json], name : String) -> Result[String?, @core.Reason] {
  match obj.get(name) {
    Some(String(value)) => Ok(Some(value))
    Some(_) => Err(invalid_query_reason("field must be string: " + name))
    None => Ok(None)
  }
}

fn extract_optional_int(obj : Map[String, Json], name : String) -> Result[Int?, @core.Reason] {
  match obj.get(name) {
    Some(Number(value, ..)) => Ok(Some(value.to_int()))
    Some(_) => Err(invalid_query_reason("field must be number: " + name))
    None => Ok(None)
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

fn extract_limit(obj : Map[String, Json]) -> Result[Int, @core.Reason] {
  match obj.get("limit") {
    Some(Number(value, ..)) => {
      let limit = value.to_int()
      if limit <= 0 {
        Err(invalid_query_reason("limit must be positive"))
      } else if limit > 1000 {
        Err(invalid_query_reason("limit must be <= 1000"))
      } else {
        Ok(limit)
      }
    }
    Some(_) => Err(invalid_query_reason("field must be number: limit"))
    None => Ok(100)
  }
}

fn validate_cursor(value : String?) -> Result[String?, @core.Reason] {
  match value {
    Some(cursor) => match @timeline_event_v3_8.decode_cursor(cursor) {
      Some(_) => Ok(Some(cursor))
      None => Err(invalid_query_reason("invalid cursor"))
    }
    None => Ok(None)
  }
}

fn download_url_for_job(job : @export_job_v4_6.JobRecord) -> String? {
  match job.status {
    @export_job_v4_6.JobStatus::Done => ()
    _ => return None
  }
  match job.input {
    @export_job_v4_6.JobInput::Metrics(input) => {
      if input.format == "jsonl" {
        Some("/v4.6/metrics/export/jobs/" + job.id + "/result.jsonl")
      } else {
        Some("/v4.6/metrics/export/jobs/" + job.id + "/result.csv")
      }
    }
    @export_job_v4_6.JobInput::Timeline(_) => Some("/v4.6/timeline/export/jobs/" + job.id + "/result.jsonl")
  }
}

fn parse_metrics_body(body : String) -> Result[@export_job_v4_6.MetricsJobInput, @core.Reason] {
  let obj = match extract_body_json(body) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let entity_id = match extract_string_field(obj, "entityId") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let from_time = match extract_optional_int(obj, "fromLogicalTime") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let to_time = match extract_optional_int(obj, "toLogicalTime") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let format = match extract_string_field(obj, "format") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  if format != "jsonl" && format != "csv" {
    return Err(invalid_query_reason("invalid format"))
  }
  Ok({ entity_id, from_logical_time: from_time, to_logical_time: to_time, format })
}

fn parse_timeline_body(body : String) -> Result[@export_job_v4_6.TimelineJobInput, @core.Reason] {
  let obj = match extract_body_json(body) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let entity_id = match extract_string_field(obj, "entityId") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let from_time = match extract_optional_int(obj, "fromLogicalTime") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let to_time = match extract_optional_int(obj, "toLogicalTime") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let limit = match extract_limit(obj) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let cursor_value = match extract_optional_string(obj, "cursor") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let cursor = match validate_cursor(cursor_value) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let format = match extract_string_field(obj, "format") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  if format != "jsonl" {
    return Err(invalid_query_reason("invalid format"))
  }
  Ok({
    entity_id,
    from_logical_time: from_time,
    to_logical_time: to_time,
    limit,
    cursor,
    format,
  })
}

///|
fn handle_metrics_job_create(req : ApiRequest) -> ApiResponse {
  let body = match req.body {
    Some(text) => text
    None => return response_json(400, error_envelope_json(invalid_query_reason("missing body")))
  }
  let input = match parse_metrics_body(body) {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let job = @job_store_v4_6.create_job(
    @export_job_v4_6.JobKind::Metrics,
    @export_job_v4_6.JobInput::Metrics(input),
  )
  response_json(200, @export_job_v4_6.job_json(job, download_url_for_job(job)))
}

///|
fn handle_timeline_job_create(req : ApiRequest) -> ApiResponse {
  let body = match req.body {
    Some(text) => text
    None => return response_json(400, error_envelope_json(invalid_query_reason("missing body")))
  }
  let input = match parse_timeline_body(body) {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let job = @job_store_v4_6.create_job(
    @export_job_v4_6.JobKind::Timeline,
    @export_job_v4_6.JobInput::Timeline(input),
  )
  response_json(200, @export_job_v4_6.job_json(job, download_url_for_job(job)))
}

fn handle_job_status(job_id : String, expected_kind : @export_job_v4_6.JobKind) -> ApiResponse {
  let job = match @job_store_v4_6.get_job_and_step(job_id) {
    Some(value) => value
    None => return response_json(404, error_envelope_json(job_not_found_reason(job_id)))
  }
  let kind_ok = match (job.kind, expected_kind) {
    (@export_job_v4_6.JobKind::Metrics, @export_job_v4_6.JobKind::Metrics) => true
    (@export_job_v4_6.JobKind::Timeline, @export_job_v4_6.JobKind::Timeline) => true
    _ => false
  }
  if !kind_ok {
    return response_json(404, error_envelope_json(job_not_found_reason(job_id)))
  }
  response_json(200, @export_job_v4_6.job_json(job, download_url_for_job(job)))
}

fn handle_metrics_result_jsonl(job_id : String) -> ApiResponse {
  let job = match @job_store_v4_6.get_job(job_id) {
    Some(value) => value
    None => return response_json(404, error_envelope_json(job_not_found_reason(job_id)))
  }
  match job.input {
    @export_job_v4_6.JobInput::Metrics(input) => {
      if input.format != "jsonl" {
        return response_json(400, error_envelope_json(invalid_query_reason("invalid format")))
      }
      response_jsonl(200, @metrics_job_v4_6.export_jsonl(input))
    }
    _ => response_json(404, error_envelope_json(job_not_found_reason(job_id)))
  }
}

fn handle_metrics_result_csv(job_id : String) -> ApiResponse {
  let job = match @job_store_v4_6.get_job(job_id) {
    Some(value) => value
    None => return response_json(404, error_envelope_json(job_not_found_reason(job_id)))
  }
  match job.input {
    @export_job_v4_6.JobInput::Metrics(input) => {
      if input.format != "csv" {
        return response_json(400, error_envelope_json(invalid_query_reason("invalid format")))
      }
      response_csv(200, @metrics_job_v4_6.export_csv(input))
    }
    _ => response_json(404, error_envelope_json(job_not_found_reason(job_id)))
  }
}

fn handle_timeline_result_jsonl(job_id : String) -> ApiResponse {
  let job = match @job_store_v4_6.get_job(job_id) {
    Some(value) => value
    None => return response_json(404, error_envelope_json(job_not_found_reason(job_id)))
  }
  match job.input {
    @export_job_v4_6.JobInput::Timeline(input) => {
      let (body, next_cursor) = @timeline_job_v4_6.export_page(input)
      response_jsonl_with_cursor(200, body, next_cursor)
    }
    _ => response_json(404, error_envelope_json(job_not_found_reason(job_id)))
  }
}

///|
pub fn handle_request(req : ApiRequest) -> ApiResponse {
  if req.http_method == "POST" && req.path == "/v4.6/metrics/export/jobs" {
    return handle_metrics_job_create(req)
  }
  if req.http_method == "POST" && req.path == "/v4.6/timeline/export/jobs" {
    return handle_timeline_job_create(req)
  }
  let metrics_status_prefix = "/v4.6/metrics/export/jobs/"
  if req.http_method == "GET" && req.path.has_prefix(metrics_status_prefix) {
    let suffix = substring_from(req.path, metrics_status_prefix.length())
    if suffix.has_suffix("/result.jsonl") {
      let job_id = substring_range(suffix, 0, suffix.length() - "/result.jsonl".length())
      if job_id.length() == 0 {
        return response_json(404, error_envelope_json(job_not_found_reason(job_id)))
      }
      return handle_metrics_result_jsonl(job_id)
    }
    if suffix.has_suffix("/result.csv") {
      let job_id = substring_range(suffix, 0, suffix.length() - "/result.csv".length())
      if job_id.length() == 0 {
        return response_json(404, error_envelope_json(job_not_found_reason(job_id)))
      }
      return handle_metrics_result_csv(job_id)
    }
    let job_id = suffix
    if job_id.length() == 0 {
      return response_json(404, error_envelope_json(job_not_found_reason(job_id)))
    }
    return handle_job_status(job_id, @export_job_v4_6.JobKind::Metrics)
  }
  let timeline_status_prefix = "/v4.6/timeline/export/jobs/"
  if req.http_method == "GET" && req.path.has_prefix(timeline_status_prefix) {
    let suffix = substring_from(req.path, timeline_status_prefix.length())
    if suffix.has_suffix("/result.jsonl") {
      let job_id = substring_range(suffix, 0, suffix.length() - "/result.jsonl".length())
      if job_id.length() == 0 {
        return response_json(404, error_envelope_json(job_not_found_reason(job_id)))
      }
      return handle_timeline_result_jsonl(job_id)
    }
    let job_id = suffix
    if job_id.length() == 0 {
      return response_json(404, error_envelope_json(job_not_found_reason(job_id)))
    }
    return handle_job_status(job_id, @export_job_v4_6.JobKind::Timeline)
  }
  response_json(
    404,
    error_envelope_json(@core.Reason::with_context(
      "ROUTE_NOT_FOUND",
      "route not found",
      [
        ("target", "runtime"),
        ("level", "error"),
        ("hint", "Use /v4.6/metrics/export/jobs"),
      ],
    )),
  )
}
