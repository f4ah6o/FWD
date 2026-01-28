#!/usr/bin/env bash
set -euo pipefail

moon check
moon test
moon run cli -- validate schema/fwd_schema.yaml
moon run cli -- schema/fwd_schema.yaml /tmp/fwd_schema.ir.json
diff -u schema/fwd_schema.ir.json /tmp/fwd_schema.ir.json
