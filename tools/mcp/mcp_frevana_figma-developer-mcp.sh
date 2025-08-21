#!/bin/bash

# MCP Configuration for Framelink Figma MCP
# {
#   "id": "mcp_frevana_figma-developer-mcp",
#   "name": "Framelink Figma MCP",
#   "category": "Design",
#   "description": "MCP server to provide Figma layout information to AI coding agents like Cursor. Give your coding agent access to your Figma data to implement designs in any framework in one-shot.",
#   "author": "GLips",
#   "tags": ["design", "figma", "ui", "layout"],
#   "homepage": "https://github.com/GLips/Figma-Context-MCP",
#   "config": [
#     {
#       "key": "command",
#       "value": "npx",
#       "is_user_fill": false,
#       "fill_fields": []
#     },
#     {
#       "key": "args",
#       "value": ["-y", "figma-developer-mcp", "--figma-api-key=$FIGMA_API_KEY$", "--stdio"],
#       "is_user_fill": true,
#       "fill_fields": [
#         {
#           "input_type": "password",
#           "out_type": "string",
#           "replace_placehold": "$FIGMA_API_KEY$",
#           "desc": "Figma API access token",
#           "doc": "https://github.com/GLips/Figma-Context-MCP#getting-started",
#           "placeholder": "FIGMA_ API KEY"
#         }
#       ]
#     },
#     {
#       "key": "enabled",
#       "value": true,
#       "is_user_fill": false,
#       "fill_fields": []
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
PNPM_CMD="$FREVANA_HOME/bin/pnpm"
NPX_CMD="$FREVANA_HOME/bin/npx"

# Check if npx exists
if [ ! -f "$NPX_CMD" ]; then
    echo "Error: npx not found at $NPX_CMD"
    echo "Please ensure Node.js is properly installed in FREVANA_HOME."
    exit 1
fi

# Pre-install figma-developer-mcp package to avoid installation delay during runtime
echo "Installing figma-developer-mcp package..."
$PNPM_CMD install figma-developer-mcp || {
    echo "Warning: Failed to pre-install figma-developer-mcp package. It will be installed on first use."
}

echo "Figma Developer MCP installed"