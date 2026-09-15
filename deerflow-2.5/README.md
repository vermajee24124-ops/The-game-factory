# DeerFlow 2.5

An open-source, Game-Research-focused overlay for DeerFlow 2.x.

## Purpose

DeerFlow remains the Research + Understanding + Planning brain. The rest of The Game Factory remains unchanged:

`Game Bible -> DeerFlow 2.5 -> Game Bible/Research Pack -> Atomic Task DAG -> Ruflo -> OpenSandbox -> DeepSeek Harness -> Godot -> QA`

DeerFlow 2.5 does not replace the coding, sandbox, routing, or Godot layers.

## Research behavior

A research mission is driven by three controls:

- objectives: what must be answered before completion
- target time: normally 30-45 minutes
- hard limit: normally 60 minutes

The agent may finish early when the objectives and quality gates are complete. It must not finish solely because a timer expired.

Quality gates:

1. decompose the brief into research questions
2. research independent branches in parallel where possible
3. collect source URLs and notes
4. verify high-impact claims against multiple sources
5. detect unresolved contradictions
6. reflect on missing information and expand the plan when needed
7. compress findings into durable project notes
8. produce a final Game Research Pack
9. produce an Atomic Task DAG for the downstream factory

## Open-source tool policy

Default bundled/integrated components are selected for open-source licensing and local/self-hosted use. Third-party services are adapters, not hard dependencies.

Core optional integrations:

- Tavily adapter: external web search when credentials are provided
- GitHub MCP: repository/code context; MIT licensed server
- Playwright: browser automation; Apache-2.0
- Crawl4AI: open web crawling/extraction; Apache-2.0 with attribution requirements
- Trafilatura: article extraction; Apache-2.0 for supported current versions
- Docling: PDF/document conversion; MIT code license
- Qdrant: durable semantic research memory; Apache-2.0
- Consensus adapter: optional academic search provider

The default distribution does not vendor proprietary SDKs, paid model weights, API keys, or closed SaaS binaries.

## Universal MCP

The overlay is designed around a dynamic MCP registry. Servers are discovered and loaded only when needed, so a large tool catalog does not have to be placed into every model context.

Supported patterns:

- stdio MCP servers
- Streamable HTTP MCP servers
- SSE compatibility where supported by the upstream DeerFlow runtime

Every server should have an explicit permission profile and an allowlist of tools.

## Local model recommendation

For the low-cost NVIDIA T4 profile, use an open-weight Qwen3 14B quantized build through Ollama or another supported local runtime, with thinking/reasoning enabled. The model is replaceable; the research orchestration is not tied to one provider.

## License

DeerFlow is MIT licensed. This repository's additions are intended to remain open-source. See `LICENSES.md` for third-party component licensing notes. The license of each dependency must be preserved when distributed.

## Status

This branch contains the DeerFlow 2.5 integration/overlay and public report material for The Game Factory. It is not a byte-for-byte re-publication of the upstream DeerFlow repository.
