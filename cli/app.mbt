///|
fn usage() -> String {
  "usage: fwdc <schema.yaml> [output.json]\n       fwdc presets\n       fwdc validate <schema.yaml>"
}

///|
fn print_presets() -> Unit {
  for name in @compiler.builtin_rule_names() {
    println(name)
  }
}

///|
fn read_input(path : String) -> String? {
  let input_result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match input_result {
    Ok(text) => Some(text)
    Err(err) => {
      println("read error: " + err.to_string())
      None
    }
  }
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
    let input_opt = read_input(input_path)
    match input_opt {
      Some(input) => {
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
                    println("validation error: " + reason.code() + ": " + reason.message())
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
      None => 1
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
