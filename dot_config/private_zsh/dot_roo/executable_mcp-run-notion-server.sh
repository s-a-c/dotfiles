#!/usr/bin/env bash

# mcp-run-notion-server.sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Construct the JSON string for the header. The shell will correctly
# expand ${NOTION_BEARER_TOKEN} with its value from the environment.
export OPENAPI_MCP_HEADERS="{\"Authorization\": \"Bearer ${NOTION_BEARER_TOKEN}\", \"Notion-Version\": \"2022-06-28\"}"

# Use exec to replace the script process with the server process.
# This is cleaner and more efficient.
exec bunx --bun @notionhq/notion-mcp-server
