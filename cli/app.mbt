///|
fn usage() -> String {
  "usage: fwdc <schema.yaml> [output.json]\n       fwdc presets\n       fwdc validate <schema.yaml> [--baseline <baseline.yaml>] [--format json|--json]"
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
  let write_result : Result[Unit, @fs.IOError] =
    try? @fs.write_string_to_file(path, output)
  match write_result {
    Ok(_) => true
    Err(err) => {
      println("write error: " + err.to_string())
      false
    }
  }
}

///|
fn format_reason(reason : @core.Reason) -> String {
  @compiler.reason_to_human_line(reason)
}

///|
fn has_breaking(reasons : Array[@core.Reason]) -> Bool {
  for reason in reasons {
    if reason.code() == "BreakingChange" || reason.code() == "MigrationRequired" {
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
      @core.Reason::new("ResolveFailure", msg)
    @compiler.CompileError::ValidationFailure(reason) => reason
  }
}

///|
pub fn run(args : Array[String]) -> Int {
  if args.length() == 0 {
    println(usage())
    return 1
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
    } else {}
    let input_result = read_input_result(input_path)
    match input_result {
      Ok(input) => {
        match baseline_path {
          Some(path) => {
            let baseline_result = read_input_result(path)
            match baseline_result {
              Ok(baseline) => {
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
              }
              Err(err) => {
                if json_output {
                  let reasons : Array[@core.Reason] = []
                  reasons.push(@core.Reason::new(
                    "ReadFailure",
                    "read error: " + err.to_string(),
                  ))
                  println(@compiler.validation_json_string(false, reasons))
                } else {
                  println("read error: " + err.to_string())
                }
                1
              }
            }
          }
          None => {
            if json_output {
              match @compiler.parse_yaml(input) {
                Ok(schema) => {
                  match @compiler.resolve_schema(schema) {
                    Ok(resolved) => {
                      match @compiler.validate_schema(resolved) {
                        Ok(_) => {
                          println(@compiler.validation_json_string(true, []))
                          0
                        }
                        Err(reason) => {
                          println(@compiler.validation_json_string(false, [reason]))
                          1
                        }
                      }
                    }
                    Err(err) => {
                      let reason = reason_from_compile_error(err)
                      println(@compiler.validation_json_string(false, [reason]))
                      1
                    }
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
                Ok(schema) => {
                  match @compiler.resolve_schema(schema) {
                    Ok(resolved) => {
                      match @compiler.validate_schema(resolved) {
                        Ok(_) => {
                          println("ok")
                          0
                        }
                        Err(reason) => {
                          println(
                            "validation error: " + reason.code() + ": " + reason.message(),
                          )
                          1
                        }
                      }
                    }
                    Err(err) => {
                      println(@compiler.describe_error(err))
                      1
                    }
                  }
                }
                Err(err) => {
                  println(@compiler.describe_error(err))
                  1
                }
              }
            }
          }
        }
      }
      Err(err) => {
        if json_output {
          let reasons : Array[@core.Reason] = []
          reasons.push(@core.Reason::new(
            "ReadFailure",
            "read error: " + err.to_string(),
          ))
          println(@compiler.validation_json_string(false, reasons))
        } else {
          println("read error: " + err.to_string())
        }
        1
      }
    }
  } else {
    let input_path = args[0]
    let output_path = if args.length() > 1 { Some(args[1]) } else { None }
    let input_opt = read_input(input_path)
    match input_opt {
      Some(input) => {
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
      }
      None => 1
    }
  }
}
