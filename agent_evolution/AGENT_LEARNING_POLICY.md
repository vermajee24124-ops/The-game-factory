# Agent Learning Policy

This system does not train an LLM.

The external LLM remains an API-powered reasoning service. The thing that evolves is the Godot agent software.

## What gets learned

The agent accumulates:
- tool schemas and safe invocation patterns
- Godot 4.7.2 usage playbooks
- project-architecture patterns
- asset workflows
- scene-building recipes
- debugging and repair recipes
- visual verification procedures
- runtime QA procedures
- optimization checklists
- plugin integration recipes
- benchmark tasks and regression tests
- project memory

## Evidence rule

A skill is not considered learned just because a model generated text about it. The skill should have a recipe, expected inputs/outputs, a verification method, and ideally a runnable smoke test.

## Video research

Use Agent Reach for discovery, search, metadata, transcripts, and upstream web/video tooling. Use Gemini video understanding for a limited high-value sample because full video analysis has API quotas.

The research pipeline stores compact technical notes and extracts testable actions. It should not copy long transcripts or proprietary game assets into the repository.

## Third-party plugins

The ecosystem file is a catalog, not permission to execute arbitrary third-party code. For each plugin, the agent should first inspect license, declared Godot version, dependencies, tool surface, security model, and integration docs. Only then can a sandboxed smoke test be created.

## Continuous evolution

Research -> Skill extraction -> Tool mapping -> Playbook -> Smoke test -> Benchmark -> Agent configuration update -> Regression test.

The model itself is not retrained.
