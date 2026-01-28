///|
test "run validate" {
  inspect(run(["validate", "examples/schema_v1.yaml"]), content="0")
}

///|
test "run presets" {
  inspect(run(["presets"]), content="0")
}
