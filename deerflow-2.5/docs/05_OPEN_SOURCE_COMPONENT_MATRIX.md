# DeerFlow 2.5 — Open-Source Component Matrix

The baseline distribution favors source-available/open-source components that can be self-hosted. External APIs are adapters, not mandatory bundled dependencies.

| Capability | Component | License / model | Packaging policy |
|---|---|---|---|
| Agent runtime | DeerFlow | MIT | Upstream source must remain attributed and license preserved |
| Search | SearXNG | AGPL-3.0-or-later | Run as a separate service; do not silently relicense it as part of the core |
| Web crawling | Crawl4AI | Apache-2.0 | Optional packaged dependency |
| Text extraction | Trafilatura | Apache-2.0 | Optional packaged dependency |
| Browser automation | Playwright | Apache-2.0 | Optional packaged dependency |
| Documents | Docling | MIT | Optional packaged dependency |
| Vector memory | Qdrant | Apache-2.0 | Optional external service |
| Repo context | GitHub MCP Server | MIT | Optional MCP integration |
| External web search | Tavily | Service/API | Adapter only; not part of open-source baseline |
| Academic search | Consensus | Service/API | Adapter only; not part of open-source baseline |

## Policy

A dependency must not be described as fully free/unlimited merely because its source is public or its SDK is open-source. Hosted APIs can have separate pricing, quotas and terms.

For every release, regenerate a dependency/license inventory and preserve each required notice. Keep AGPL services isolated when their copyleft scope could otherwise create licensing ambiguity for the core distribution.
