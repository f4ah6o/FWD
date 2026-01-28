///|
test "run validate" {
  inspect(run(["validate", "examples/schema_v1.yaml"]), content="0")
}

///|
test "run validate examples" {
  inspect(run(["validate", "examples/fwd_schema_change_valid.yaml"]), content="0")
  inspect(run(["validate", "examples/effects_v1.yaml"]), content="0")
  inspect(run(["validate", "examples/fwd_schema_change_invalid.yaml"]), content="1")
}

///|
test "run validate baseline" {
  inspect(
    run([
      "validate",
      "examples/remove-state.yaml",
      "--baseline",
      "examples/fwd_schema_change_valid.yaml",
    ]),
    content="1",
  )
  inspect(
    run([
      "validate",
      "examples/remove-transition.yaml",
      "--baseline",
      "examples/fwd_schema_change_valid.yaml",
    ]),
    content="1",
  )
  inspect(
    run([
      "validate",
      "examples/remove-transition-with-migration.yaml",
      "--baseline",
      "examples/fwd_schema_change_valid.yaml",
    ]),
    content="1",
  )
  inspect(
    run([
      "validate",
      "examples/remove-state-with-migration.yaml",
      "--baseline",
      "examples/fwd_schema_change_valid.yaml",
    ]),
    content="1",
  )
  inspect(
    run([
      "validate",
      "examples/modify-transition.yaml",
      "--baseline",
      "examples/fwd_schema_change_valid.yaml",
      "--format",
      "json",
    ]),
    content="1",
  )
  inspect(
    run([
      "validate",
      "examples/modify-transition-with-migration.yaml",
      "--baseline",
      "examples/fwd_schema_change_valid.yaml",
    ]),
    content="1",
  )
}

///|
test "run presets" {
  inspect(run(["presets"]), content="0")
}
