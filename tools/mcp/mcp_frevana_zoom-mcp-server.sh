#!/bin/bash

# MCP Configuration for Zoom MCP Server
# {
#   "id": "mcp_frevana_zoom-mcp-server",
#   "name": "Zoom MCP Server",
#   "category": "Communication",
#   "description": "A Model Context Protocol server for integrating with Zoom video conferencing platform",
#   "author": "javaprogrammerlb",
#   "tags": ["zoom", "video-conferencing", "communication", "meeting"],
#   "homepage": "https://github.com/javaprogrammerlb/zoom-mcp-server",
#   "config": [
#     {
#       "key": "command",
#       "value": "npx",
#       "is_user_fill": false
#     },
#     {
#       "key": "args",
#       "value": ["-y", "@yitianyigexiangfa/zoom-mcp-server@latest"],
#       "is_user_fill": false
#     },
#     {
#       "key": "env",
#       "value": {
#         "ZOOM_ACCOUNT_ID": "${ZOOM_ACCOUNT_ID}",
#         "ZOOM_CLIENT_ID": "${ZOOM_CLIENT_ID}",
#         "ZOOM_CLIENT_SECRET": "${ZOOM_CLIENT_SECRET}"
#       },
#       "is_user_fill": true,
#       "fill_fields": [
#         {
#           "input_type": "text",
#           "out_type": "string",
#           "replace_placehold": "${ZOOM_ACCOUNT_ID}",
#           "desc": "Zoom Account ID for authentication",
#           "doc": "https://github.com/javaprogrammerlb/zoom-mcp-server#2-steps-to-play-with-zoom-mcp-server",
#           "placeholder": "ZOOM_ACCOUNT_ID"
#         },
#         {
#           "input_type": "text",
#           "out_type": "string",
#           "replace_placehold": "${ZOOM_CLIENT_ID}",
#           "desc": "Zoom Client ID for authentication",
#           "doc": "https://github.com/javaprogrammerlb/zoom-mcp-server#2-steps-to-play-with-zoom-mcp-server",
#           "placeholder": "ZOOM_CLIENT_ID"
#         },
#         {
#           "input_type": "password",
#           "out_type": "string",
#           "replace_placehold": "${ZOOM_CLIENT_SECRET}",
#           "desc": "Zoom Client Secret for authentication",
#           "doc": "https://github.com/javaprogrammerlb/zoom-mcp-server#2-steps-to-play-with-zoom-mcp-server",
#           "placeholder": "ZOOM_CLIENT_SECRET"
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

# Pre-install @yitianyigexiangfa/zoom-mcp-server package to avoid installation delay during runtime
echo "Installing @yitianyigexiangfa/zoom-mcp-server package..."
$NPM_CMD install @yitianyigexiangfa/zoom-mcp-server || {
    echo "Warning: Failed to pre-install @yitianyigexiangfa/zoom-mcp-server package. It will be installed on first use."
}

echo "MCP Zoom Server installed"