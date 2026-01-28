///|
fn usage() -> String {
  "usage: fwdc <schema.yaml> [output.json]"
}

///|
fn main {
  let args = @env.args()
  if args.length() == 0 {
    println(usage())
    return
  }
  let input_path = args[0]
  let output_path = if args.length() > 1 { Some(args[1]) } else { None }

  let input_result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(input_path)
  let input = match input_result {
    Ok(text) => text
    Err(err) => {
      println("read error: " + err.to_string())
      return
    }
  }

  match @compiler.compile_yaml(input) {
    Ok(ir) => {
      let json = @compiler.ir_to_json(ir)
      let output = json.stringify(indent=2)
      match output_path {
        Some(path) => {
          let write_result : Result[Unit, @fs.IOError] =
            try? @fs.write_string_to_file(path, output)
          match write_result {
            Ok(_) => println("ok")
            Err(err) => println("write error: " + err.to_string())
          }
        }
        None => println(output)
      }
    }
    Err(err) => println(@compiler.describe_error(err))
  }
}
