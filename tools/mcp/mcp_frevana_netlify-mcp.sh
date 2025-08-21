#!/bin/bash

# MCP Configuration for Netlify MCP
# {
#   "id": "mcp_frevana_netlify-mcp",
#   "name": "Netlify MCP",
#   "category": "Deployment",
#   "description": "A Model Context Protocol server for integrating with Netlify deployment platform, allowing AI agents to deploy and manage sites on Netlify.",
#   "author": "Netlify",
#   "tags": ["deployment", "netlify", "hosting", "jamstack"],
#   "homepage": "https://github.com/netlify/netlify-mcp",
#   "config": [
#     {
#       "key": "command",
#       "value": "npx",
#       "is_user_fill": false,
#       "fill_fields": []
#     },
#     {
#       "key": "args",
#       "value": ["-y", "@netlify/mcp"],
#       "is_user_fill": false,
#       "fill_fields": []
#     },
#     {
#       "key": "env",
#       "value": {
#         "NETLIFY_PERSONAL_ACCESS_TOKEN": "$NETLIFY_PERSONAL_ACCESS_TOKEN$"
#       },
#       "is_user_fill": true,
#       "fill_fields": [
#         {
#           "input_type": "password",
#           "out_type": "string",
#           "replace_placehold": "$NETLIFY_PERSONAL_ACCESS_TOKEN$",
#           "desc": "Netlify Personal Access Token",
#           "doc": "https://docs.netlify.com/build/build-with-ai/netlify-mcp-server/#get-a-new-pat",
#           "placeholder": "NETLIFY_PERSONAL_ACCESS_TOKEN"
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
NPM_CMD="$FREVANA_HOME/bin/npm"
NPX_CMD="$FREVANA_HOME/bin/npx"

# Check if npx exists
if [ ! -f "$NPX_CMD" ]; then
    echo "Error: npx not found at $NPX_CMD"
    echo "Please ensure Node.js is properly installed in FREVANA_HOME."
    exit 1
fi

# Pre-install @netlify/mcp package to avoid installation delay during runtime
# echo "Installing @netlify/mcp package..."
# $NPM_CMD install @netlify/mcp || {
#     echo "Warning: Failed to pre-install @netlify/mcp package. It will be installed on first use."
# }

echo "MCP Netlify is ready"