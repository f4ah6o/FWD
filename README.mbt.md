# FWD (v1 prototype)

## CLI

```
moon run cli -- <schema.yaml> [output.json]
moon run cli -- validate <schema.yaml>
moon run cli -- presets
```

- If `output.json` is omitted, JSON IR is printed to stdout.
- Example input: `examples/schema_v1.yaml`.

### Validation JSON Output (v1.1)

```
moon run cli -- validate <schema.yaml> --json
moon run cli -- validate <schema.yaml> --format json
moon run cli -- validate <schema.yaml> --baseline <baseline.yaml> --json
```

- `stdout` is JSON only (no extra human-readable text).
- Exit code is `0` on success, `1` on failure.
- Expected validation failures are reported as JSON with `"ok": false`.

## Builtin Rule Presets

These preset rule names are reserved and provided by the compiler resolve stage:

- `hasAtLeastOneState`
- `hasAtLeastOneTransition`
- `allReferencesResolved`
- `noBreakingChanges`
- `noBreakingChangesOrMigrationDefined`

Notes:

- Preset rules can be referenced in `transitions.rules` by name.
- A schema-defined rule **cannot** reuse a builtin name; the resolve stage will fail.
- Schema-defined rules are allowed and live in `rules:`.

## Example

Minimal YAML (v1):

```
fwdVersion: "1.0"
schemaVersion: "1.0"

states:
  - Draft
  - Released

transitions:
  - name: submit
    from: Draft
    to: Released
    rules:
      - hasAtLeastOneState
```
