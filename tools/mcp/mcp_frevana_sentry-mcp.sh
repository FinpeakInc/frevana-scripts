#!/bin/bash

# MCP Configuration for Sentry
# {
#   "id": "mcp_frevana_sentry-mcp",
#   "name": "Sentry",
#   "category": "Monitoring",
#   "description": "A Model Context Protocol server for integrating with Sentry error tracking platform, allowing AI agents to monitor and analyze application errors and performance issues.",
#   "author": "Sentry",
#   "tags": ["monitoring", "sentry", "error-tracking", "performance", "debugging"],
#   "homepage": "https://github.com/getsentry/sentry-mcp",
#   "config": [
#     {
#       "key": "command",
#       "value": "npx",
#       "is_user_fill": false,
#       "fill_fields": []
#     },
#     {
#       "key": "args",
#       "value": ["@sentry/mcp-server@latest"],
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
#         "SENTRY_ACCESS_TOKEN": "$SENTRY_ACCESS_TOKEN$",
#         "SENTRY_HOST": "$SENTRY_HOST$"
#       },
#       "is_user_fill": true,
#       "fill_fields": [
#         {
#           "input_type": "password",
#           "out_type": "string",
#           "replace_placehold": "$SENTRY_ACCESS_TOKEN$",
#           "desc": "Sentry Access Token",
#           "doc": "https://docs.sentry.io/product/mcp-server/#authentication",
#           "placeholder": "SENTRY_ACCESS_TOKEN"
#         },
#         {
#           "input_type": "text",
#           "out_type": "string",
#           "replace_placehold": "$SENTRY_HOST$",
#           "desc": "Sentry Host",
#           "doc": "https://docs.sentry.io/product/mcp-server/#configuration",
#           "placeholder": "sentry.io or your custom Sentry instance"
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
NPX_CMD="$FREVANA_HOME/bin/npx"

# Check if npx exists
if [ ! -f "$NPX_CMD" ]; then
    echo "Error: npx not found at $NPX_CMD"
    echo "Please ensure Node.js is properly installed in FREVANA_HOME."
    exit 1
fi

echo "MCP Sentry installed"