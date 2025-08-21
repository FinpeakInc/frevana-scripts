#!/bin/bash

# MCP Configuration for Slack
# {
#   "id": "mcp_frevana_slack-mcp-server",
#   "name": "Slack",
#   "category": "Communication",
#   "description": "The most powerful MCP Slack Server with no permission requirements, Apps support, multiple transports Stdio and SSE, DMs, Group DMs and smart history fetch logic.",
#   "author": "korotovsky",
#   "homepage": "https://github.com/korotovsky/slack-mcp-server/",
#   "tags": ["communication", "slack", "messaging", "collaboration", "team"],
#   "config": [
#     {
#       "key": "command",
#       "value": "npx",
#       "is_user_fill": false,
#       "fill_fields": []
#     },
#     {
#       "key": "args",
#       "value": ["-y", "slack-mcp-server@latest", "--transport", "stdio"],
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
#         "SLACK_MCP_XOXP_TOKEN": "$SLACK_MCP_XOXP_TOKEN$",
#         "SLACK_MCP_ADD_MESSAGE_TOOL": true
#       },
#       "is_user_fill": true,
#       "fill_fields": [
#         {
#           "input_type": "password",
#           "out_type": "string",
#           "replace_placehold": "$SLACK_MCP_XOXP_TOKEN$",
#           "desc": "SLACK XOXP/XOXB Token",
#           "doc": "https://github.com/korotovsky/slack-mcp-server/blob/master/docs/01-authentication-setup.md#alternative-using-slack_mcp_xoxp_token-user-oauth",
#           "placeholder": "SLACK XOXP/XOXB Token"
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

# Pre-install slack-mcp-server package to avoid installation delay during runtime
echo "Installing slack-mcp-server package..."
$NPM_CMD install slack-mcp-server@latest || {
    echo "Warning: Failed to pre-install slack-mcp-server package. It will be installed on first use."
}

echo "MCP Slack Server installed"