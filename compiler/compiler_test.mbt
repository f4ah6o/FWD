///|
fn sample_yaml() -> String {
  let value : String =
    #|fwdVersion: "1.0"
    #|schemaVersion: "1.0"
    #|
    #|states:
    #|  - Draft
    #|  - Reviewing
    #|  - Released
    #|
    #|entities:
    #|  - name: Schema
    #|    initialState: Draft
    #|    attributes:
    #|      - name: title
    #|        type: String
    #|      - name: version
    #|        type: String
    #|
    #|reasons:
    #|  - code: ValidationFailure
    #|    message: Validation failed
    #|
    #|boundaries:
    #|  - name: Reviewer
    #|
    #|transitions:
    #|  - name: submitForReview
    #|    from: Draft
    #|    to: Reviewing
    #|    rules:
    #|      - hasAtLeastOneState
    #|      - hasAtLeastOneTransition
    #|
    #|  - name: approve
    #|    from: Reviewing
    #|    to: Released
    #|    rules:
    #|      - allReferencesResolved
    #|
    #|  - name: deprecate
    #|    from: Released
    #|    to: Released
    #|    effects:
    #|      - notifyDependentSchemas
    #|
    #|effects:
    #|  - name: notifyDependentSchemas
    #|    kind: async
    #|
  value
}

///|
fn yaml_missing_effect() -> String {
  let value : String =
    #|fwdVersion: "1.0"
    #|schemaVersion: "1.0"
    #|
    #|states:
    #|  - Draft
    #|  - Released
    #|
    #|transitions:
    #|  - name: submit
    #|    from: Draft
    #|    to: Released
    #|    effects:
    #|      - notify
    #|
  value
}

///|
fn yaml_conflicting_rule() -> String {
  let value : String =
    #|fwdVersion: "1.0"
    #|schemaVersion: "1.0"
    #|
    #|states:
    #|  - Draft
    #|  - Released
    #|
    #|rules:
    #|  - name: hasAtLeastOneState
    #|    type: preset
    #|
    #|transitions:
    #|  - name: submit
    #|    from: Draft
    #|    to: Released
    #|    rules:
    #|      - hasAtLeastOneState
    #|
  value
}

///|
test "compile yaml to ir json" {
  match compile_yaml(sample_yaml()) {
    Ok(ir) => {
      let output = ir_to_json(ir).stringify(indent=2)
      inspect(output, content=(
        
        #|{
        #|  "version": "1.0",
        #|  "fwdVersion": "1.0",
        #|  "stateGraph": {
        #|    "nodes": [
        #|      "Draft",
        #|      "Reviewing",
        #|      "Released"
        #|    ],
        #|    "edges": {
        #|      "Draft": {
        #|        "Reviewing": {
        #|          "name": "submitForReview"
        #|        }
        #|      },
        #|      "Reviewing": {
        #|        "Released": {
        #|          "name": "approve"
        #|        }
        #|      },
        #|      "Released": {
        #|        "Released": {
        #|          "name": "deprecate"
        #|        }
        #|      }
        #|    }
        #|  },
        #|  "entities": {
        #|    "Schema": {
        #|      "name": "Schema",
        #|      "state": "Draft",
        #|      "dataSchema": null
        #|    }
        #|  },
        #|  "transitions": {
        #|    "submitForReview": {
        #|      "name": "submitForReview",
        #|      "from": "Draft",
        #|      "to": "Reviewing",
        #|      "ruleRefs": [
        #|        "hasAtLeastOneState",
        #|        "hasAtLeastOneTransition"
        #|      ],
        #|      "effectRefs": [],
        #|      "inputSchema": null
        #|    },
        #|    "approve": {
        #|      "name": "approve",
        #|      "from": "Reviewing",
        #|      "to": "Released",
        #|      "ruleRefs": [
        #|        "allReferencesResolved"
        #|      ],
        #|      "effectRefs": [],
        #|      "inputSchema": null
        #|    },
        #|    "deprecate": {
        #|      "name": "deprecate",
        #|      "from": "Released",
        #|      "to": "Released",
        #|      "ruleRefs": [],
        #|      "effectRefs": [
        #|        "notifyDependentSchemas"
        #|      ],
        #|      "inputSchema": null
        #|    }
        #|  },
        #|  "rules": {
        #|    "hasAtLeastOneState": {
        #|      "type": "preset",
        #|      "name": "hasAtLeastOneState"
        #|    },
        #|    "hasAtLeastOneTransition": {
        #|      "type": "preset",
        #|      "name": "hasAtLeastOneTransition"
        #|    },
        #|    "allReferencesResolved": {
        #|      "type": "preset",
        #|      "name": "allReferencesResolved"
        #|    }
        #|  },
        #|  "reasons": {
        #|    "ValidationFailure": {
        #|      "code": "ValidationFailure",
        #|      "message": "Validation failed",
        #|      "contextSchema": null
        #|    }
        #|  },
        #|  "effects": {
        #|    "notifyDependentSchemas": {
        #|      "name": "notifyDependentSchemas",
        #|      "kind": "async"
        #|    }
        #|  }
        #|}
      ))
    }
    Err(err) => fail(describe_error(err))
  }
}

///|
test "validation json output" {
  let reasons : Array[@core.Reason] = []
  reasons.push(@core.Reason::with_context(
    "BreakingChange",
    "transition modified",
    [("transition", "submit"), ("field", "from"), ("candidate", "Reviewing"), ("baseline", "Draft")],
  ))
  reasons.push(@core.Reason::with_context(
    "MigrationRequired",
    "breaking change requires migration",
    [("count", "1")],
  ))
  let output = validation_json_string(false, reasons)
  assert_true(output.contains("\"ok\": false"))
  assert_true(output.contains("\"errorCount\": 2"))
  assert_true(output.contains("\"code\": \"BreakingChange\""))
  assert_true(output.contains("\"code\": \"MigrationRequired\""))
  assert_true(output.contains(
    "\"baseline\": \"Draft\",\n        \"candidate\": \"Reviewing\",\n        \"field\": \"from\",\n        \"transition\": \"submit\"",
  ))
}

///|
test "validation unknown effect" {
  match compile_yaml(yaml_missing_effect()) {
    Err(ValidationFailure(reason)) => {
      inspect(reason.code(), content="unknown_effect")
    }
    _ => fail("expected validation failure")
  }
}

///|
test "resolve builtin rule conflict" {
  match compile_yaml(yaml_conflicting_rule()) {
    Err(ResolveFailure(_)) => ()
    _ => fail("expected resolve failure")
  }
}
