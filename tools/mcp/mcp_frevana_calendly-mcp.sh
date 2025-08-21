#!/bin/bash

# MCP Configuration for Calendly
# {
#   "id": "mcp_frevana_calendly-mcp",
#   "name": "Calendly",
#   "category": "Communication",
#   "description": "A Model Context Protocol server for integrating with Calendly.",
#   "author": "meAmitPatil",
#   "tags": ["communication", "calendly", "scheduling", "appointment"],
#   "homepage": "https://github.com/meAmitPatil/calendly-mcp-server",
#   "config": [
#     {
#       "key": "command",
#       "value": "npx",
#       "is_user_fill": false,
#       "fill_fields": []
#     },
#     {
#       "key": "args",
#       "value": ["calendly-mcp-server"],
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
#         "CALENDLY_API_KEY": "$CALENDLY_API_KEY$"
#       },
#       "is_user_fill": true,
#       "fill_fields": [
#         {
#           "input_type": "password",
#           "out_type": "string",
#           "replace_placehold": "$CALENDLY_API_KEY$",
#           "desc": "CALENDLY API KEY",
#           "doc": "https://github.com/meAmitPatil/calendly-mcp-server?tab=readme-ov-file#option-1-personal-access-token-pat",
#           "placeholder": "CALENDLY_API_KEY"
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
    exit 1
fi

# Pre-install calendly-mcp-server package to avoid installation delay during runtime
# echo "Installing calendly-mcp-server package..."
# $NPM_CMD install calendly-mcp-server || {
#     echo "Warning: Failed to pre-install calendly-mcp-server package. It will be installed on first use."
# }

echo "MCP Calendly installed"