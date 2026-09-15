# DeerFlow 2.5 — Validation Plan

The public release should be evaluated on the real workload it is meant to serve, not on the number of integrations installed.

## Core tests

### Research depth

Use representative game/app missions and verify that the system:

- creates a research plan before searching
- explores multiple independent branches
- follows promising leads
- revises the plan when evidence changes the problem
- records provenance
- detects contradictions
- produces a coherent synthesis

### Long-horizon reliability

Run missions near the 60-minute budget and verify:

- checkpoints are written
- a worker failure does not lose prior findings
- a resumed run continues from a consistent state
- partial outputs are not confused with final outputs

### Tool routing

Verify that:

- only required tool schemas are promoted
- disabled tools cannot execute
- write tools require allowlist approval
- an unhealthy provider does not block unrelated providers
- tool outputs are linked to the correct mission/task

### Game Factory hand-off

Verify that the output can be consumed directly by the existing downstream stack:

`Game Research Pack -> Atomic Task DAG -> Ruflo -> OpenSandbox -> DeepSeek Harness -> Godot`

## Release gate

A candidate release is acceptable only when the installation test, research mission tests, checkpoint/resume tests, MCP permission tests, secret-scan, dependency/license scan, and downstream hand-off tests pass.

## Benchmark discipline

Do not publish a single benchmark score as proof that DeerFlow 2.5 is universally better than DeerFlow. Report workload-specific results, model, tool configuration, search provider, hardware, latency and failure rate so comparisons remain reproducible.
