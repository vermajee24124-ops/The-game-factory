# Agent evolution plan

This project does NOT train or fine-tune an LLM.

The external model remains an API service. The part being improved is the Godot agent itself.

## Base

Start from the open-source Godot AI add-on v4.2.1 and keep upstream attribution/license notices.

## Evolution targets

1. Tool surface: expand and normalize editor/runtime tools.
2. Planning: add explicit task decomposition and dependency tracking.
3. Memory: persist project facts, decisions, failures, successful patterns and test history.
4. Verification: require evidence after mutations.
5. Visual QA: viewport screenshots, frame/video sampling, scene diffs and visual checks.
6. Runtime QA: scripted input, play/stop, logs, errors, profiler snapshots.
7. Repair: diagnose -> patch -> validate -> retest loops.
8. Asset workflows: provider adapters for image, material, mesh and audio generation.
9. Project awareness: index scenes, scripts, resources, settings and dependencies.
10. Model routing: keep models external and let the gateway choose or route by capability.
11. Regression tests: maintain a benchmark suite of real Godot tasks.
12. Self-improvement: use research and test results to change the agent code/configuration/prompt packs, not model weights.

## Source usage

Agent Reach and other research tools may collect publicly available references. Use only sources and assets whose licenses/terms permit the intended use. Transform reference material into concise technical notes, test cases, tool requirements and documentation rather than copying protected material into the agent source.