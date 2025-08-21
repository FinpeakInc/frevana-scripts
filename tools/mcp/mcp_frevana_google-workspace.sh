#!/bin/bash

# MCP Configuration for Google Workspace
# {
#   "id": "mcp_frevana_google-workspace",
#   "name": "Google Workspace",
#   "category": "Productivity",
#   "description": "Connect to Google Workspace for reading and writing documents, spreadsheets, and presentations.\nhttps://github.com/taylorwilsdon/google_workspace_mcp",
#   "author": "taylorwilsdon",
#   "homepage": "https://github.com/taylorwilsdon/google_workspace_mcp",
#   "tags": ["productivity", "google", "workspace", "documents"],
#   "config": [
#     {
#       "key": "command",
#       "value": "uvx",
#       "is_user_fill": false,
#       "fill_fields": []
#     },
#     {
#       "key": "args",
#       "value": ["workspace-mcp"],
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
#         "GOOGLE_OAUTH_CLIENT_ID": "$GOOGLE_OAUTH_CLIENT_ID$",
#         "GOOGLE_OAUTH_CLIENT_SECRET": "$GOOGLE_OAUTH_CLIENT_SECRET$",
#         "USER_GOOGLE_EMAIL": "$USER_GOOGLE_EMAIL$"
#       },
#       "is_user_fill": true,
#       "fill_fields": [
#         {
#           "input_type": "text",
#           "out_type": "string",
#           "replace_placehold": "$GOOGLE_OAUTH_CLIENT_ID$",
#           "desc": "OAuth client ID from Google Cloud (used by both legacy auth and OAuth 2.1)",
#           "doc": "https://github.com/taylorwilsdon/google_workspace_mcp#configuration",
#           "placeholder": "GOOGLE_OAUTH_CLIENT_ID"
#         },
#         {
#           "input_type": "text",
#           "out_type": "string",
#           "replace_placehold": "$GOOGLE_OAUTH_CLIENT_SECRET$",
#           "desc": "OAuth client secret (used by both legacy auth and OAuth 2.1)",
#           "doc": "https://github.com/taylorwilsdon/google_workspace_mcp#configuration",
#           "placeholder": "GOOGLE_OAUTH_CLIENT_SECRET"
#         },
#         {
#           "input_type": "text",
#           "out_type": "string",
#           "replace_placehold": "$USER_GOOGLE_EMAIL$",
#           "desc": "Default email for single-user auth",
#           "doc": "https://github.com/taylorwilsdon/google_workspace_mcp#configuration",
#           "placeholder": "USER_GOOGLE_EMAIL"
#         }
#       ]
#     }
#   ]
# }
#
# command_preq: python, uv

# Check if FREVANA_HOME is set
if [ -z "$FREVANA_HOME" ]; then
    echo "Error: FREVANA_HOME environment variable is not set."
    exit 1
fi

# Set uv/uvx path with FREVANA_HOME prefix
UV_CMD="$FREVANA_HOME/bin/uv"
UVX_CMD="$FREVANA_HOME/bin/uvx"

# Check if uv exists
if [ ! -f "$UV_CMD" ]; then
    echo "Error: uv not found at $UV_CMD"
    echo "Please ensure uv is properly installed in FREVANA_HOME."
    exit 1
fi

# Check if uvx exists
if [ ! -f "$UVX_CMD" ]; then
    echo "Error: uvx not found at $UVX_CMD"
    echo "Please ensure uv is properly installed in FREVANA_HOME."
    exit 1
fi

# Let UVX install workspace-mcp

echo "MCP Google Workspace is ready"