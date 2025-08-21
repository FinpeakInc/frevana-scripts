#!/bin/bash

# MCP Configuration for Notion
# {
#   "id": "mcp_frevana_notion-api",
#   "name": "Notion",
#   "category": "Productivity",
#   "description": "Connect to Notion workspace for reading and writing pages, databases, and blocks through the Notion API",
#   "author": "Notion",
#   "homepage": "https://github.com/makenotion/notion-mcp-server",
#   "tags": ["productivity", "notion", "workspace", "database"],
#   "config": [
#     {
#       "key": "command",
#       "value": "npx",
#       "is_user_fill": false,
#       "fill_fields": []
#     },
#     {
#       "key": "args",
#       "value": ["-y", "@notionhq/notion-mcp-server"],
#       "is_user_fill": false,
#       "fill_fields": []
#     },
#     {
#       "key": "enabled",
#       "value": true,
#       "is_user_fill": false,
#       "fill_fields": []
#     },
#     {
#       "key": "env",
#       "value": {
#         "OPENAPI_MCP_HEADERS": "{\"Authorization\": \"Bearer $NOTION_TOKEN$\",\"Notion-Version\": \"2022-06-28\"}"
#       },
#       "is_user_fill": true,
#       "fill_fields": [
#         {
#           "input_type": "password",
#           "out_type": "string",
#           "replace_placehold": "$NOTION_TOKEN$",
#           "desc": "Notion Integration Token",
#           "doc": "https://github.com/makenotion/notion-mcp-server#installation",
#           "placeholder": "NOTION_TOKEN"
#         }
#       ]
#     }
#   ]
# }
#
# command_preq: node

# Check if FREVANA_HOME is set
if [ -z "$FREVANA_HOME" ]; then
    echo "Error: FREVANA_HOME environment variable is not set."
    exit 1
fi

# Set npm/npx path with FREVANA_HOME prefix
NPM_CMD="$FREVANA_HOME/bin/npm"
NPX_CMD="$FREVANA_HOME/bin/npx"

# Check if npx exists
if [ ! -f "$NPX_CMD" ]; then
    echo "Error: npx not found at $NPX_CMD"
    echo "Please ensure Node.js is properly installed in FREVANA_HOME."
    exit 1
fi

# Pre-install @notionhq/notion-mcp-server package to avoid installation delay during runtime
echo "Installing @notionhq/notion-mcp-server package..."
$NPM_CMD install @notionhq/notion-mcp-server || {
    echo "Warning: Failed to pre-install @notionhq/notion-mcp-server package. It will be installed on first use."
}

echo "MCP Notion API installed"