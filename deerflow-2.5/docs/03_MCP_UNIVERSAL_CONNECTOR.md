# DeerFlow 2.5 — Universal MCP Connector

## Goal

DeerFlow 2.5 should be able to connect to compatible MCP servers without changing core research logic. MCP is an extension boundary, not a reason to embed every third-party tool into the repository.

## Supported connection classes

- stdio MCP servers for local/self-hosted tools
- HTTP/SSE MCP servers for remote tools
- OAuth-backed remote MCP where the upstream server supports the required flow

## Safety model

1. Tool discovery is read-only by default.
2. Tool schemas are deferred until a task needs them.
3. Read-only tools may be promoted automatically when policy permits.
4. Write/destructive tools require an explicit allowlist.
5. Credentials are supplied by environment/secret references, never committed.
6. MCP server commands come only from trusted operator configuration.
7. Every promoted tool should carry source/server identity for auditability.

## Default open-source MCP candidates

- GitHub MCP Server (MIT)
- Playwright/browser MCP adapters with compatible open-source licensing
- Filesystem MCP servers with explicit path scoping
- Docling MCP (MIT)
- Optional database/knowledge MCP servers selected by operator needs

## External service adapters

Tavily and Consensus may be connected by configuration, but they are not bundled as source dependencies of the open-source baseline. Users can replace them with self-hosted/open alternatives.

## Dynamic routing

A research subtask should be classified first, then the router should search the MCP catalog and promote only the required schemas. This avoids context inflation when a large catalog is installed.

## Failure handling

- server unavailable -> mark tool unhealthy and continue with a fallback
- authentication failure -> stop that tool only and record the failure
- invalid schema/command -> do not load the server
- tool timeout -> checkpoint and retry according to policy
- conflicting outputs -> preserve both evidence records and send them to verification

## Public distribution rule

The DeerFlow 2.5 repository contains configuration examples and integration adapters. It must not ship user credentials, private MCP endpoints, proprietary SDK binaries, or provider secrets.
