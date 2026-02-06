# FWD (v1 prototype)

## CLI

```
moon run cli -- <schema.yaml> [output.json]
moon run cli -- validate <schema.yaml>
moon run cli -- presets
moon run cli -- runtime available <schema.yaml> --state <state> [--input <json>]
moon run cli -- runtime execute <schema.yaml> --state <state> --transition <id> [--input <json>]
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

## Runtime (v1)

Compute available/blocked transitions from IR and a current state snapshot.
This is pure computation: no state mutation or side effects.
`--input` accepts an object of rule results (e.g. `{ "canApprove": true }`)
or `{ "rules": { ... } }`.

Example output:

```
{
  "availableTransitions": [
    { "id": "approve", "to": "Approved" }
  ],
  "blockedTransitions": [
    {
      "id": "reject",
      "reasons": [
        {
          "reasonVersion": 1,
          "code": "RULE_NOT_SATISFIED",
          "level": "info",
          "target": "rule",
          "message": "Rule not satisfied",
          "hint": "Provide rule result true for this transition"
        }
      ]
    }
  ]
}
```

### Runtime execute (v1)

Execute a specific transition (pure computation only). Output is deterministic JSON.

Example output:

```
{
  "ok": true,
  "transition": {
    "id": "approve",
    "from": "Draft",
    "to": "Approved"
  },
  "effects": []
}
```

## Runtime execute (v1)

Execute applies a single transition to the current state in a **pure, deterministic** way and returns a JSON envelope.

### Usage
```sh
fwd runtime execute <schema.yaml> --state <state> --transition <id> --input <json>
```

### Exit codes (frozen)
- `0`: request is valid; outcome is encoded in JSON (`executed` or `blocked`)
- `1`: invalid transition request (`not_found` or `not_available`)
- `2`: invalid `--input` JSON (input/usage error)

### Fixtures (contract locks)
See `examples/runtime_execute/`:
- `expected_executed.json`
- `expected_blocked.json`
- `expected_not_found.json`
- `expected_not_available.json`

## Runtime execute (v1)

Execute applies a single transition to the current state in a **pure, deterministic** way and returns a JSON envelope.

### Usage
```sh
fwd runtime execute <schema.yaml> --state <state> --transition <id> --input <json>
```

### Exit codes (frozen)
- `0`: request is valid; outcome is encoded in JSON (`executed` or `blocked`)
- `1`: invalid transition request (`not_found` or `not_available`)
- `2`: invalid `--input` JSON (input/usage error)

### Fixtures (contract locks)
See `examples/runtime_execute/`:
- `expected_executed.json`
- `expected_blocked.json`
- `expected_not_found.json`
- `expected_not_available.json`

## Hypermedia Resource (v1)

`hypermedia/resource` is a **new contract** layered on top of runtime results.
It does **not** replace the frozen runtime/CLI JSON.

- Projection only: no evaluation, no classification, no inference.
- Reason v1 is passed through as-is.
- JSON and HTML are two projections of the same resource.

Fixture path: `examples/hypermedia_show/`.

## Resource v2 (M11)

v2 では **resource を first-class な契約**として追加し、JSON / HTML / MX の各投影を **resource v2** から決定的に生成します。  
v1 の resource / runtime / Reason 契約は保持され、**新しい surface として併存**します。

### Endpoints / Formats
- `GET /v2/resource?state=...&format=v2-json|v2-html|v2-mx`
  - `v2-json`: resource v2 JSON（input schema / payload state / field errors を含む）
  - `v2-html`: tmpx による決定的 HTML
  - `v2-mx`: mhx 向け mx-* 属性付き HTML
- `POST /v2/resource/validate`
  - payload を検証し、エラー時は **Reason v1** を返却
  - 成功時は resource v2 HTML（Execute CTA を含む）を返却

### Fixtures (Contract Locks)
- `examples/resource_v2/expected.json`
- `examples/resource_v2/expected.html`
- `examples/resource_v2/expected_mx.html`

### Guarantees
- **no-inference**：投影層は推測しない
- **deterministic**：順序・構造は fixture で固定
- **v1 untouched**：既存の v1 契約は変更しない

## v2.1 Persistence Endpoints

v2.1 は entity の保存・履歴・実行を **新しい surface** として提供します。

### Endpoints
- `POST /v2.1/entities`（create）
- `GET /v2.1/entities/:id`（get）
- `GET /v2.1/entities/:id/history`（history JSON）
- `GET /v2.1/entities/:id/history?format=v2_1_html`（history HTML, swap target: `.fwd-history`）
- `POST /v2.1/entities/:id/execute`（execute-and-persist）

### Fixtures (Contract Locks)
- `examples/api_v2_1/`
- `examples/api_v2_1/history_html/expected.html`

## Effects plan (v2.2)

Generate a deterministic effects plan (no I/O). This is a **planning-only** surface: it lists what effects would be executed for a transition, without executing them.

```
fwdc effects plan <schema.yaml> --entity <id> --state <state> --transition <id> --input <json>
```

Fixtures (contract locks):
- `examples/effects_v2_2/cli_planned/expected.json`
- `examples/effects_v2_2/cli_skipped/expected.json`

## Effects execute (v2.2)

Execute an effects plan using the deterministic stub runner (no external I/O). This surface consumes a plan JSON and emits a fixture-locked execution result.

```
fwdc effects execute --plan <plan.json>
```

Fixtures (contract locks):
- `examples/effects_v2_2/execute/expected_executed.json`
- `examples/effects_v2_2/execute/expected_skipped.json`

## Effects HTTP endpoints (v2.2)

v2.2 exposes effects planning and execution over a pure HTTP adapter surface.

- `POST /v2.2/effects/plan` → EffectsPlan JSON (same shape as `fwdc effects plan`)
- `POST /v2.2/effects/execute` → EffectsExecutionResult JSON (same shape as `fwdc effects execute`)

Contract locks:
- `examples/api_v2_2/effects_plan/expected.json`
- `examples/api_v2_2/effects_execute/expected.json`

Notes:
- Execution uses an adapter boundary; the HTTP runner enforces an allowlist and sends an idempotency header.

## Effects record/replay (v2.2)

v2.2 includes a deterministic replay harness for HTTP effects execution. Tests use a cassette-driven transport to avoid real network calls.

Fixtures (contract locks):
- `examples/effects_v2_2/record_replay/cassette_example.json`
- `examples/effects_v2_2/record_replay/expected_executed.json`

Replay is used by injecting the cassette transport into the HTTP runner’s transport boundary.

## Effects record (v2.2)

Record HTTP effect execution into a cassette file (developer workflow). The command requires an allowlist prefix and writes a deterministic cassette JSON.

```
fwdc effects record --plan <plan.json> --cassette <cassette.json> --allow https://api.example.com/
```

Optional:
- `--out <execution.json>` writes the execution result to a file (the result is also printed to stdout).

Contract locks:
- `examples/effects_v2_2/record_cli/expected_cassette.json`
- `examples/effects_v2_2/record_cli/expected_execution.json`

## Effects run (v2.2)

```
fwdc effects run --plan <plan.json> --config <config.json>
```

Optional:
- `--cassette <cassette.json>`: replay recorded HTTP interactions.

Config example (v2.2):

```
{
  "allowlist": ["https://api.example.com/"],
  "timeoutMs": 5000
}
```

Contract locks:
- `examples/effects_v2_2/real_runner/config.json`
- `examples/effects_v2_2/real_runner/expected_execution.json`

## v3 HTTP endpoints

v3 introduces hardened execution surfaces (policy, effects hardening, unified timeline)
as new immutable contracts.

See `IMPLEMENTATION_PLAN.md` → “v3 Implementation Plan” and “Frozen Contracts (v3)”.
Fixtures live under `examples/api_v3/`.

## v3.1 Executor endpoint

v3.1 adds a detailed executor surface for effects execution.
See `IMPLEMENTATION_PLAN.md` → “Frozen Contracts (v3.1)”.
Fixtures live under `examples/api_v3_1/`.

## v3.2 Timeline HTML

v3.2 exposes timeline HTML as a standalone surface.
See `IMPLEMENTATION_PLAN.md` → “Frozen Contracts (v3.2)”.
Fixtures live under `examples/api_v3_2/`.

## v3.3 Timeline filter + paging

v3.3 adds filter and paging controls for the timeline UI.
See `IMPLEMENTATION_PLAN.md` → “Frozen Contracts (v3.3)”.
Fixtures live under `examples/api_v3_3/`.

## v3.4 Timeline drilldown

v3.4 adds a timeline event detail partial (`/v3.4/timeline/event/:id`).
See `IMPLEMENTATION_PLAN.md` → “Frozen Contracts (v3.4)”.
Fixtures live under `examples/api_v3_4/`.

## v3.4 Timeline mx drilldown view

v3.4 adds an mx-enabled timeline view that swaps event detail partials.
See `IMPLEMENTATION_PLAN.md` → “Frozen Contracts (v3.4)”.
Fixtures live under `examples/v3_4/timeline_mx/`.

## v3.5 Timeline export (JSONL)

v3.5 adds `/v3.5/timeline/export.jsonl` (deterministic export).
See `IMPLEMENTATION_PLAN.md` → “Frozen Contracts (v3.5)”.
Fixtures live under `examples/api_v3_5/`.

## v3.6 Metrics

v3.6 adds `/v3.6/metrics` (deterministic metrics snapshot).
See `IMPLEMENTATION_PLAN.md` → “Frozen Contracts (v3.6)”.
Fixtures live under `examples/api_v3_6/`.

## v3.7 Metrics export (JSONL)

v3.7 adds `/v3.7/metrics/export.jsonl` (deterministic metrics export).
See `IMPLEMENTATION_PLAN.md` → “Frozen Contracts (v3.7)”.
Fixtures live under `examples/api_v3_7/`.

## v3.8 Timeline event list (filters + paging)

v3.8 adds `/v3.8/timeline/events` (filtered event list HTML).
See `IMPLEMENTATION_PLAN.md` → “Frozen Contracts (v3.8)”.
Fixtures live under `examples/api_v3_8/`.

## v3.9 Timeline event paging (detail)

v3.9 adds `/v3.9/timeline/event/:id` with prev/next paging.
See `IMPLEMENTATION_PLAN.md` → “Frozen Contracts (v3.9)”.
Fixtures live under `examples/api_v3_9/`.

## v4 Canonical JSON

v4 defines a canonical JSON surface (draft fixtures).
See `IMPLEMENTATION_PLAN.md` → “Frozen Contracts (v4)”.
Fixtures live under `examples/v4/canonical/`.

## v4 HTML/MX projections

v4 HTML/MX projections are fixture-locked.
See `IMPLEMENTATION_PLAN.md` → “Frozen Contracts (v4)”.
Fixtures live under `examples/v4/html/`.

## v4 HTTP adapter

v4 adds read-only HTTP endpoints under `/v4/*` (resource + timeline list/detail).
See `IMPLEMENTATION_PLAN.md` → “Frozen Contracts (v4)”.
Fixtures live under `examples/api_v4/`.

## v4.2 metrics UI

v4.2 adds a read-only metrics HTML/MX surface under `/v4.2/metrics`.
See `IMPLEMENTATION_PLAN.md` → “Frozen Contracts (v4.2)”.
Fixtures live under `examples/api_v4_2/`.

## M8: mhx client hypermedia execution (browser harness)

M8 adds a minimal browser harness to verify that **mx-enabled HTML** is interpreted by `mhx`
and that clicking an mx control triggers a network request.

### Build
```
moon build ui/client/main --target js
```

### Run
Serve `ui/client/main/index.html` via any static server (a file:// URL will not work because the
script path must resolve).

Example:
```
# from repo root
python3 -m http.server 8000
```

Then open:
- `http://localhost:8000/ui/client/main/index.html`

### Expected behavior
- The page loads `_build/js/.../main.js`.
- `main.js` calls `@client.init_mhx_client()`.
- Clicking the mx-enabled button/link triggers a request to the deterministic endpoint pattern:
  - `/hypermedia/transition/<id>`
- The rendered HTML uses:
  - `mx-target=".fwd-resource"`
  - `mx-swap="outerHTML"`

### Notes
- This harness is a smoke test only; it proves client wiring and request triggering.
- Server-side endpoints can be stubbed; the harness is valid as long as the network request fires.

## Reason Mini-Spec (v1)

All validation, baseline, and runtime failures must be normalized to the same
Reason shape. This is the cross-cutting, machine-readable vocabulary for v1.

### Fields
- `reasonVersion`: fixed to `1`
- `code`: stable identifier (`SCREAMING_SNAKE`)
- `level`: `error | warn | info`
- `target`: `schema | state | transition | rule | effect | baseline | runtime`
- `message`: human explanation (non-localized)
- `hint` (optional): fix guidance

### JSON Schema

```
schema/reason.schema.v1.json
```

### Example

```
{
  "reasonVersion": 1,
  "code": "STATE_NOT_FOUND",
  "level": "error",
  "target": "transition",
  "message": "Transition refers to an undefined state",
  "hint": "Define the state or fix the transition.from value"
}
```

## Frozen Contracts

This project follows a strict contract-freeze discipline.
All stable JSON/HTML/CLI surfaces are locked by fixtures and tests.

See `IMPLEMENTATION_PLAN.md` → “Frozen Contracts” for the full index.

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
- Reserved-name conflicts are reported as `RESERVED_WORD_CONFLICT`.
- Schema-defined rules are allowed and live in `rules:`.

## Breaking Change Taxonomy (v1)

Breaking changes must return a stable `Reason.code` and are machine-detectable
via baseline diff.

### Categories
- State removed -> `STATE_REMOVED`
- Transition removed -> `TRANSITION_REMOVED`
- Transition modified -> `TRANSITION_MODIFIED`
- Schema version incompatible -> `SCHEMA_VERSION_INCOMPATIBLE`

### Example (state removed)

Old:

```
states:
  - Draft
  - Released
```

New:

```
states:
  - Draft
```

Reason:

```
{
  "reasonVersion": 1,
  "code": "STATE_REMOVED",
  "level": "error",
  "target": "state",
  "message": "State 'Released' was removed",
  "hint": "Add a migration or restore the state"
}
```

### Examples (per-code)

```
{
  "reasonVersion": 1,
  "code": "TRANSITION_REMOVED",
  "level": "error",
  "target": "transition",
  "message": "transition removed",
  "hint": "Transition removed; re-add transition or define migration mapping"
}
```

```
{
  "reasonVersion": 1,
  "code": "TRANSITION_MODIFIED",
  "level": "error",
  "target": "transition",
  "message": "transition modified",
  "hint": "Transition modified; review compatibility and add migration if needed"
}
```

```
{
  "reasonVersion": 1,
  "code": "MIGRATION_REQUIRED",
  "level": "error",
  "target": "baseline",
  "message": "breaking change requires migration",
  "hint": "Breaking changes detected; provide migration definitions"
}
```

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
