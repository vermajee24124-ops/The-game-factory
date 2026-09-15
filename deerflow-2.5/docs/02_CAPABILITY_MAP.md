# DeerFlow 2.5 — Capability Map

This document maps the capabilities DeerFlow already provides or can safely extend, without turning the project into a game engine or coding factory.

## Core DeerFlow responsibilities

1. Long-horizon agent runtime.
2. Lead-agent planning and subagent delegation.
3. Memory/context management.
4. Skills and MCP integration.
5. Web research and retrieval orchestration.
6. Browser interaction where configured.
7. Files and sandboxed execution where configured.
8. Durable task/run state and resumability.

## Research extensions

### Retrieval
- SearXNG as an optional self-hosted metasearch service.
- Tavily as an external adapter, not a mandatory dependency.
- Search-provider abstraction so alternative providers can be plugged in without changing mission logic.

### Web extraction
- Crawl4AI for open-source crawling.
- Trafilatura for article/text extraction and cleanup.

### Browser
- Playwright for deterministic browser automation.
- Browser tasks should run in the configured sandbox and must be permissioned.

### Documents
- Docling for PDF, DOCX, HTML and related document parsing.
- Normalized document output should enter the research evidence pipeline rather than the main prompt as raw text.

### Memory
- Qdrant as an optional open-source vector store for durable semantic retrieval.
- Project research should be stored as structured notes plus provenance metadata.

### Code/repository research
- GitHub MCP for repository, issue, pull-request and workflow context.
- Repository access is read-only by default during research; writes require explicit policy approval.

### Academic research
- Consensus remains an optional external adapter. It is useful for academic evidence but is not part of the open-source baseline.

## Capability loading rule

Do not expose all schemas to the model on every call. Use dynamic discovery/deferred promotion and task-based routing. The model should receive only the tools relevant to its current subtask.

## Out of scope

The project must not absorb a game engine, a full coding agent, an asset-generation studio, or the downstream execution pipeline. Those remain separate services in The Game Factory.
