///|
fn main {
  let raw_args = @sys.get_cli_args()
  let args = if raw_args.length() > 0 { raw_args.sub(start=1).to_array() } else { [] }
  @sys.exit(run(args))
}
