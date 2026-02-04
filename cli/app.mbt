///|
fn usage() -> String {
  "usage: fwdc <schema.yaml> [output.json]\n       fwdc presets\n       fwdc validate <schema.yaml> [--baseline <baseline.yaml>] [--format json|--json]\n       fwdc runtime available <schema.yaml> --state <state> [--input <json>]\n       fwdc runtime execute <schema.yaml> --state <state> --transition <id> [--input <json>]\n       fwdc hypermedia show <schema.yaml> --state <state> [--input <json>]\n       fwdc effects plan <schema.yaml> --entity <id> --state <state> --transition <id> [--input <json>]\n       fwdc effects execute --plan <json>\n       fwdc effects record --plan <plan.json> --cassette <cassette.json> [--out <execution.json>] --allow <prefix> [--allow <prefix>]\n       fwdc effects run --plan <plan.json> --config <config.json> [--cassette <cassette.json>]"
}

///|
fn print_presets() -> Unit {
  for name in @compiler.builtin_rule_names() {
    println(name)
  }
}

///|
fn read_input(path : String) -> String? {
  match read_input_result(path) {
    Ok(text) => Some(text)
    Err(err) => {
      println("read error: " + err.to_string())
      None
    }
  }
}

///|
fn read_input_result(path : String) -> Result[String, @fs.IOError] {
  try? @fs.read_file_to_string(path)
}

///|
fn write_output(path : String, output : String) -> Bool {
  let write_result : Result[Unit, @fs.IOError] = try? @fs.write_string_to_file(
    path, output,
  )
  match write_result {
    Ok(_) => true
    Err(err) => {
      println("write error: " + err.to_string())
      false
    }
  }
}

///|
fn record_send_stub(
  _req : @effects_exec_adapters_v2_2.HttpRequest,
) -> Result[@effects_exec_adapters_v2_2.HttpResponse, @core.Reason] {
  Ok({ status: 200, body: "{\"ok\":true}" })
}

///|
fn format_reason(reason : @core.Reason) -> String {
  @compiler.reason_to_human_line(reason)
}

///|
fn has_breaking(reasons : Array[@core.Reason]) -> Bool {
  for reason in reasons {
    if reason.code() == "STATE_REMOVED" ||
      reason.code() == "TRANSITION_REMOVED" ||
      reason.code() == "TRANSITION_MODIFIED" ||
      reason.code() == "MIGRATION_REQUIRED" {
      return true
    }
  }
  false
}

///|
fn reason_from_compile_error(err : @compiler.CompileError) -> @core.Reason {
  match err {
    @compiler.CompileError::ParseFailure(msg) =>
      @core.Reason::new("ParseFailure", msg)
    @compiler.CompileError::ResolveFailure(msg) =>
      if msg.has_prefix("rule name conflicts with builtin: ") {
        @core.Reason::with_context(
          "RESERVED_WORD_CONFLICT",
          msg,
          [
            ("target", "rule"),
            ("hint", "Builtin rule names are reserved"),
          ],
        )
      } else {
        @core.Reason::new("ResolveFailure", msg)
      }
    @compiler.CompileError::ValidationFailure(reason) => reason
  }
}

///|
pub fn run(args : Array[String]) -> Int {
  if args.length() == 0 {
    println(usage())
    return 1
  }
  if args[0] == "hypermedia" {
    if args.length() < 4 {
      println(usage())
      return 1
    }
    if args[1] != "show" {
      println(usage())
      return 1
    }
    if args.length() < 5 {
      println(usage())
      return 1
    }
    let schema_path = args[2]
    let mut state : String? = None
    let mut input_json : String? = None
    for i = 3; i < args.length(); {
      let arg = args[i]
      if arg == "--state" {
        if i + 1 >= args.length() {
          println(usage())
          return 1
        }
        state = Some(args[i + 1])
        continue i + 2
      } else if arg == "--input" {
        if i + 1 >= args.length() {
          println(usage())
          return 1
        }
        input_json = Some(args[i + 1])
        continue i + 2
      } else {
        println(usage())
        return 1
      }
    } else {

    }
    let current_state = match state {
      Some(value) => value
      None => {
        println(usage())
        return 1
      }
    }
    let rule_results = match input_json {
      Some(text) =>
        match parse_rule_results(text) {
          Ok(values) => values
          Err(reason) => {
            println(runtime_error_json(reason).stringify(indent=2))
            return 2
          }
        }
      None => Map::new()
    }
    let schema_text = match read_input_result(schema_path) {
      Ok(text) => text
      Err(err) => {
        println(runtime_error_json(@core.Reason::with_context(
          "ReadFailure",
          "read error: " + err.to_string(),
          [
            ("target", "runtime"),
            ("level", "error"),
            ("hint", "Provide a valid schema path"),
          ],
        )).stringify(indent=2))
        return 1
      }
    }
    let ir = match @compiler.compile_yaml(schema_text) {
      Ok(value) => value
      Err(err) => {
        let reason = reason_from_compile_error(err)
        println(runtime_error_json(reason).stringify(indent=2))
        return 1
      }
    }
    let runtime_result = match @runtime.compute_available_transitions(
      ir,
      current_state,
      rule_results,
    ) {
      Ok(value) => value
      Err(reason) => {
        println(runtime_error_json(reason).stringify(indent=2))
        return 1
      }
    }
    let resource = @hypermedia.resource_from_runtime(runtime_result)
    let output = @hypermedia.resource_json(resource).stringify(indent=2)
    println(output)
    return 0
  }
  if args[0] == "effects" {
    if args.length() < 3 {
      println(usage())
      return 1
    }
    if args[1] != "plan" && args[1] != "execute" && args[1] != "record" && args[1] != "run" {
      println(usage())
      return 1
    }
    if args[1] == "execute" {
      if args.length() < 4 {
        println(usage())
        return 1
      }
      let mut plan_json : String? = None
      for i = 2; i < args.length(); {
        let arg = args[i]
        if arg == "--plan" {
          if i + 1 >= args.length() {
            println(usage())
            return 1
          }
          plan_json = Some(args[i + 1])
          continue i + 2
        } else {
          println(usage())
          return 1
        }
      } else {

      }
      let plan_text = match plan_json {
        Some(value) => value
        None => {
          println(usage())
          return 1
        }
      }
      let plan = match @effects_v2_2.parse_plan_json(plan_text) {
        Ok(value) => value
        Err(reason) => {
          println(runtime_error_json(reason).stringify(indent=2))
          return 2
        }
      }
      let result = @effects_v2_2.execute_plan_stub(plan)
      println(@effects_v2_2.execution_result_json(result).stringify(indent=2))
      return 0
    }
    if args[1] == "record" {
      if args.length() < 6 {
        println(usage())
        return 1
      }
      let mut plan_path : String? = None
      let mut cassette_path : String? = None
      let mut out_path : String? = None
      let allowlist : Array[String] = []
      for i = 2; i < args.length(); {
        let arg = args[i]
        if arg == "--plan" {
          if i + 1 >= args.length() {
            println(usage())
            return 1
          }
          plan_path = Some(args[i + 1])
          continue i + 2
        } else if arg == "--cassette" {
          if i + 1 >= args.length() {
            println(usage())
            return 1
          }
          cassette_path = Some(args[i + 1])
          continue i + 2
        } else if arg == "--out" {
          if i + 1 >= args.length() {
            println(usage())
            return 1
          }
          out_path = Some(args[i + 1])
          continue i + 2
        } else if arg == "--allow" {
          if i + 1 >= args.length() {
            println(usage())
            return 1
          }
          allowlist.push(args[i + 1])
          continue i + 2
        } else {
          println(usage())
          return 1
        }
      } else {

      }
      let plan_file = match plan_path {
        Some(value) => value
        None => {
          println(usage())
          return 1
        }
      }
      let cassette_file = match cassette_path {
        Some(value) => value
        None => {
          println(usage())
          return 1
        }
      }
      if allowlist.length() == 0 {
        println(runtime_error_json(@core.Reason::with_context(
          "INPUT_MISSING",
          "missing allowlist",
          [
            ("target", "runtime"),
            ("level", "error"),
            ("hint", "Provide --allow <prefix>"),
          ],
        )).stringify(indent=2))
        return 2
      }
      let plan_text = match read_input_result(plan_file) {
        Ok(text) => text
        Err(err) => {
          println(runtime_error_json(@core.Reason::with_context(
            "ReadFailure",
            "read error: " + err.to_string(),
            [
              ("target", "runtime"),
              ("level", "error"),
              ("hint", "Provide a valid plan path"),
            ],
          )).stringify(indent=2))
          return 2
        }
      }
      let plan = match @effects_v2_2.parse_plan_json(plan_text) {
        Ok(value) => value
        Err(reason) => {
          println(runtime_error_json(reason).stringify(indent=2))
          return 2
        }
      }
      let (result, cassette) = @effects_exec_rr_v2_2.record_execute_plan(
        plan,
        allowlist,
        record_send_stub,
      )
      let cassette_json = @effects_exec_rr_v2_2.cassette_json(cassette).stringify(indent=2)
      if !write_output(cassette_file, cassette_json) {
        return 1
      }
      let exec_json = @effects_v2_2.execution_result_json(result).stringify(indent=2)
      match out_path {
        Some(path) => if !write_output(path, exec_json) { return 1 }
        None => ()
      }
      println(exec_json)
      return 0
    }
    if args[1] == "run" {
      if args.length() < 4 {
        println(usage())
        return 1
      }
      let mut plan_path : String? = None
      let mut config_path : String? = None
      let mut cassette_path : String? = None
      for i = 2; i < args.length(); {
        let arg = args[i]
        if arg == "--plan" {
          if i + 1 >= args.length() {
            println(usage())
            return 1
          }
          plan_path = Some(args[i + 1])
          continue i + 2
        } else if arg == "--config" {
          if i + 1 >= args.length() {
            println(usage())
            return 1
          }
          config_path = Some(args[i + 1])
          continue i + 2
        } else if arg == "--cassette" {
          if i + 1 >= args.length() {
            println(usage())
            return 1
          }
          cassette_path = Some(args[i + 1])
          continue i + 2
        } else {
          println(usage())
          return 1
        }
      } else {

      }
      let plan_file = match plan_path {
        Some(value) => value
        None => {
          println(usage())
          return 1
        }
      }
      let config_file = match config_path {
        Some(value) => value
        None => {
          println(usage())
          return 1
        }
      }
      let plan_text = match read_input_result(plan_file) {
        Ok(text) => text
        Err(err) => {
          println(runtime_error_json(@core.Reason::with_context(
            "ReadFailure",
            "read error: " + err.to_string(),
            [
              ("target", "runtime"),
              ("level", "error"),
              ("hint", "Provide a valid plan path"),
            ],
          )).stringify(indent=2))
          return 2
        }
      }
      let config_text = match read_input_result(config_file) {
        Ok(text) => text
        Err(err) => {
          println(runtime_error_json(@core.Reason::with_context(
            "ReadFailure",
            "read error: " + err.to_string(),
            [
              ("target", "runtime"),
              ("level", "error"),
              ("hint", "Provide a valid config path"),
            ],
          )).stringify(indent=2))
          return 2
        }
      }
      let plan = match @effects_v2_2.parse_plan_json(plan_text) {
        Ok(value) => value
        Err(reason) => {
          println(runtime_error_json(reason).stringify(indent=2))
          return 2
        }
      }
      let config = match @effects_exec_real_v2_2.parse_config_json(config_text) {
        Ok(value) => value
        Err(reason) => {
          println(runtime_error_json(reason).stringify(indent=2))
          return 2
        }
      }
      let send = match cassette_path {
        Some(path) => {
          let cassette_text = match read_input_result(path) {
            Ok(text) => text
            Err(err) => {
              println(runtime_error_json(@core.Reason::with_context(
                "ReadFailure",
                "read error: " + err.to_string(),
                [
                  ("target", "runtime"),
                  ("level", "error"),
                  ("hint", "Provide a valid cassette path"),
                ],
              )).stringify(indent=2))
              return 2
            }
          }
          let cassette = match @effects_exec_rr_v2_2.parse_cassette_json(cassette_text) {
            Ok(value) => value
            Err(reason) => {
              println(runtime_error_json(reason).stringify(indent=2))
              return 2
            }
          }
          @effects_exec_rr_v2_2.replay_transport(cassette)
        }
        None => record_send_stub
      }
      let result = @effects_exec_real_v2_2.execute_with_transport(
        plan,
        config,
        send,
      )
      let output = @effects_v2_2.execution_result_json(result).stringify(indent=2)
      println(output)
      match result.status {
        @effects_v2_2.ExecutionStatus::Failed => return 1
        _ => return 0
      }
    }
    let schema_path = args[2]
    let mut entity_id : String? = None
    let mut state : String? = None
    let mut transition_id : String? = None
    let mut input_json : String? = None
    for i = 3; i < args.length(); {
      let arg = args[i]
      if arg == "--entity" {
        if i + 1 >= args.length() {
          println(usage())
          return 1
        }
        entity_id = Some(args[i + 1])
        continue i + 2
      } else if arg == "--state" {
        if i + 1 >= args.length() {
          println(usage())
          return 1
        }
        state = Some(args[i + 1])
        continue i + 2
      } else if arg == "--transition" {
        if i + 1 >= args.length() {
          println(usage())
          return 1
        }
        transition_id = Some(args[i + 1])
        continue i + 2
      } else if arg == "--input" {
        if i + 1 >= args.length() {
          println(usage())
          return 1
        }
        input_json = Some(args[i + 1])
        continue i + 2
      } else {
        println(usage())
        return 1
      }
    } else {

    }
    let entity = match entity_id {
      Some(value) => value
      None => {
        println(usage())
        return 1
      }
    }
    let current_state = match state {
      Some(value) => value
      None => {
        println(usage())
        return 1
      }
    }
    let transition_name = match transition_id {
      Some(value) => value
      None => {
        println(usage())
        return 1
      }
    }
    let rule_results = match input_json {
      Some(text) =>
        match parse_rule_results(text) {
          Ok(values) => values
          Err(reason) => {
            println(runtime_error_json(reason).stringify(indent=2))
            return 2
          }
        }
      None => Map::new()
    }
    let schema_text = match read_input_result(schema_path) {
      Ok(text) => text
      Err(err) => {
        println(runtime_error_json(@core.Reason::with_context(
          "ReadFailure",
          "read error: " + err.to_string(),
          [
            ("target", "runtime"),
            ("level", "error"),
            ("hint", "Provide a valid schema path"),
          ],
        )).stringify(indent=2))
        return 1
      }
    }
    let ir = match @compiler.compile_yaml(schema_text) {
      Ok(value) => value
      Err(err) => {
        let reason = reason_from_compile_error(err)
        println(runtime_error_json(reason).stringify(indent=2))
        return 1
      }
    }
    return match @runtime.execute_transition(
      ir,
      current_state,
      transition_name,
      rule_results,
    ) {
      Ok(outcome) => {
        let plan = @effects_v2_2.plan_from_execution(entity, outcome)
        println(@effects_v2_2.effect_plan_json(plan).stringify(indent=2))
        0
      }
      Err(reason) => {
        println(runtime_error_json(reason).stringify(indent=2))
        1
      }
    }
  }
  if args[0] == "presets" {
    print_presets()
    return 0
  }
  if args[0] == "validate" {
    if args.length() < 2 {
      println(usage())
      return 1
    }
    let input_path = args[1]
    let mut baseline_path : String? = None
    let mut json_output = false
    for i = 2; i < args.length(); {
      let arg = args[i]
      if arg == "--baseline" {
        if i + 1 >= args.length() {
          println(usage())
          return 1
        }
        baseline_path = Some(args[i + 1])
        continue i + 2
      } else if arg == "--format" {
        if i + 1 >= args.length() {
          println(usage())
          return 1
        }
        if args[i + 1] == "json" {
          json_output = true
          continue i + 2
        }
        println(usage())
        return 1
      } else if arg == "--json" {
        json_output = true
        continue i + 1
      } else {
        println(usage())
        return 1
      }
    } else {

    }
    let input_result = read_input_result(input_path)
    match input_result {
      Ok(input) =>
        match baseline_path {
          Some(path) => {
            let baseline_result = read_input_result(path)
            match baseline_result {
              Ok(baseline) =>
                match @compiler.validate_with_baseline(input, baseline) {
                  Ok(_) => {
                    if json_output {
                      println(@compiler.validation_json_string(true, []))
                    } else {
                      println("ok")
                    }
                    0
                  }
                  Err(reasons) => {
                    if json_output {
                      println(@compiler.validation_json_string(false, reasons))
                    } else {
                      let header = if has_breaking(reasons) {
                        "error: breaking changes detected ("
                      } else {
                        "error: validation failed ("
                      }
                      println(header + reasons.length().to_string() + ")")
                      for reason in reasons {
                        println("- " + format_reason(reason))
                      }
                    }
                    1
                  }
                }
              Err(err) => {
                if json_output {
                  let reasons : Array[@core.Reason] = []
                  reasons.push(
                    @core.Reason::new(
                      "ReadFailure",
                      "read error: " + err.to_string(),
                    ),
                  )
                  println(@compiler.validation_json_string(false, reasons))
                } else {
                  println("read error: " + err.to_string())
                }
                1
              }
            }
          }
          None =>
            if json_output {
              match @compiler.parse_yaml(input) {
                Ok(schema) =>
                  match @compiler.resolve_schema(schema) {
                    Ok(resolved) =>
                      match @compiler.validate_schema(resolved) {
                        Ok(_) => {
                          println(@compiler.validation_json_string(true, []))
                          0
                        }
                        Err(reason) => {
                          println(
                            @compiler.validation_json_string(false, [reason]),
                          )
                          1
                        }
                      }
                    Err(err) => {
                      let reason = reason_from_compile_error(err)
                      println(@compiler.validation_json_string(false, [reason]))
                      1
                    }
                  }
                Err(err) => {
                  let reason = reason_from_compile_error(err)
                  println(@compiler.validation_json_string(false, [reason]))
                  1
                }
              }
            } else {
              match @compiler.parse_yaml(input) {
                Ok(schema) =>
                  match @compiler.resolve_schema(schema) {
                    Ok(resolved) =>
                      match @compiler.validate_schema(resolved) {
                        Ok(_) => {
                          println("ok")
                          0
                        }
                        Err(reason) => {
                          println(
                            "validation error: " +
                            reason.code() +
                            ": " +
                            reason.message(),
                          )
                          1
                        }
                      }
                    Err(err) => {
                      println(@compiler.describe_error(err))
                      1
                    }
                  }
                Err(err) => {
                  println(@compiler.describe_error(err))
                  1
                }
              }
            }
        }
      Err(err) => {
        if json_output {
          let reasons : Array[@core.Reason] = []
          reasons.push(
            @core.Reason::new("ReadFailure", "read error: " + err.to_string()),
          )
          println(@compiler.validation_json_string(false, reasons))
        } else {
          println("read error: " + err.to_string())
        }
        1
      }
    }
  } else {
    if args[0] == "runtime" {
      if args.length() < 4 {
        println(usage())
        return 1
      }
      let subcommand = args[1]
      if subcommand != "available" && subcommand != "execute" {
        println(usage())
        return 1
      }
      let schema_path = args[2]
      let mut state : String? = None
      let mut input_json : String? = None
      let mut transition_id : String? = None
      for i = 3; i < args.length(); {
        let arg = args[i]
        if arg == "--state" {
          if i + 1 >= args.length() {
            println(usage())
            return 1
          }
          state = Some(args[i + 1])
          continue i + 2
        } else if arg == "--transition" {
          if i + 1 >= args.length() {
            println(usage())
            return 1
          }
          transition_id = Some(args[i + 1])
          continue i + 2
        } else if arg == "--input" {
          if i + 1 >= args.length() {
            println(usage())
            return 1
          }
          input_json = Some(args[i + 1])
          continue i + 2
        } else {
          println(usage())
          return 1
        }
      } else {

      }
      let current_state = match state {
        Some(value) => value
        None => {
          println(usage())
          return 1
        }
      }
      if subcommand == "execute" && transition_id is None {
        println(usage())
        return 1
      }
      let rule_results = match input_json {
        Some(text) =>
          match parse_rule_results(text) {
            Ok(values) => values
            Err(reason) => {
              println(runtime_error_json(reason).stringify(indent=2))
              return 2
            }
          }
        None => Map::new()
      }
      let schema_text = match read_input_result(schema_path) {
        Ok(text) => text
        Err(err) => {
          println(runtime_error_json(@core.Reason::with_context(
            "ReadFailure",
            "read error: " + err.to_string(),
            [
              ("target", "runtime"),
              ("level", "error"),
              ("hint", "Provide a valid schema path"),
            ],
          )).stringify(indent=2))
          return 1
        }
      }
      let ir = match @compiler.compile_yaml(schema_text) {
        Ok(value) => value
        Err(err) => {
          let reason = reason_from_compile_error(err)
          println(runtime_error_json(reason).stringify(indent=2))
          return 1
        }
      }
      if subcommand == "available" {
        match @runtime.compute_available_transitions(
          ir,
          current_state,
          rule_results,
        ) {
          Ok(result) => {
            println(runtime_output_json(result).stringify(indent=2))
            0
          }
          Err(reason) => {
            println(runtime_error_json(reason).stringify(indent=2))
            1
          }
        }
      } else {
        let transition_name = match transition_id {
          Some(value) => value
          None => {
            println(usage())
            return 1
          }
        }
        match @runtime.execute_transition(
          ir,
          current_state,
          transition_name,
          rule_results,
        ) {
          Ok(outcome) => {
            println(runtime_execute_json(outcome).stringify(indent=2))
            0
          }
          Err(reason) => {
            println(runtime_error_json(reason).stringify(indent=2))
            1
          }
        }
      }
    } else {
    let input_path = args[0]
    let output_path = if args.length() > 1 { Some(args[1]) } else { None }
    let input_opt = read_input(input_path)
    match input_opt {
      Some(input) =>
        match @compiler.compile_yaml(input) {
          Ok(ir) => {
            let json = @compiler.ir_to_json(ir)
            let output = json.stringify(indent=2)
            match output_path {
              Some(path) => if write_output(path, output) { 0 } else { 1 }
              None => {
                println(output)
                0
              }
            }
          }
          Err(err) => {
            println(@compiler.describe_error(err))
            1
          }
        }
      None => 1
    }
    }
  }
}
