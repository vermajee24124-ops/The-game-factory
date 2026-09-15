# Open-source component and license matrix

This file records the intended default dependency policy for DeerFlow 2.5. License status can change upstream, so release automation should verify the exact pinned version before distribution.

| Component | Role | License/status | Distribution policy |
|---|---|---|---|
| ByteDance DeerFlow | Research/agent runtime | MIT | Upstream license/copyright retained |
| GitHub MCP Server | Repository/code context | MIT | Use upstream license notice |
| Playwright | Browser automation | Apache-2.0 | Use upstream notices |
| Crawl4AI | Web crawling/extraction | Apache-2.0 with attribution requirements in current releases | Keep required attribution |
| Trafilatura | Article/content extraction | Apache-2.0 for supported current versions | Avoid pre-1.8 GPLv3+ versions |
| Docling | PDF/document conversion | MIT code license; individual models may have their own licenses | Pin compatible model licenses |
| Qdrant | Semantic research memory | Apache-2.0 | Use upstream notices |
| SearXNG | Optional self-hosted metasearch | AGPL-3.0 | Run as a separate service; do not silently relicense its code |

## Closed services are optional adapters

Tavily, Consensus, Cloudflare APIs, hosted model APIs, and similar services are not bundled into the default open-source distribution. They may be configured by an operator as optional adapters.

## Important

“Open source” does not mean “everything has the same license.” DeerFlow 2.5 must preserve third-party notices and comply with the license of every distributed component.
