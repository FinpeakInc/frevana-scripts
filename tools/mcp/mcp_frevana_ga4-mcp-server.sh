#!/bin/bash

# MCP Configuration for Google Analytics
# {
#   "id": "mcp_frevana_ga4-mcp-server",
#   "name": "Google Analytics",
#   "category": "Analytics",
#   "description": "Connect to Google Analytics for reading and writing events, user properties, and custom dimensions and metrics.\nhttps://github.com/surendranb/google-analytics-mcp#test-your-setup-optional",
#   "author": "surendranb",
#   "homepage": "https://github.com/surendranb/google-analytics-mcp",
#   "tags": ["analytics", "google", "ga4", "events", "user properties"],
#   "config": [
#     {
#       "key": "command",
#       "value": "ga4-mcp-server",
#       "is_user_fill": false,
#       "fill_fields": []
#     },
#     {
#       "key": "args",
#       "value": [],
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
#         "GOOGLE_APPLICATION_CREDENTIALS": "$GOOGLE_APPLICATION_CREDENTIALS_PATH$",
#         "GA4_PROPERTY_ID": "$GA4_PROPERTY_ID$"
#       },
#       "is_user_fill": true,
#       "fill_fields": [
#         {
#           "input_type": "text",
#           "out_type": "string",
#           "replace_placehold": "$GOOGLE_APPLICATION_CREDENTIALS_PATH$",
#           "desc": "google application credentials json path",
#           "doc": "https://github.com/surendranb/google-analytics-mcp#create-service-account-in-google-cloud-console",
#           "placeholder": "google application credentials json path"
#         },
#         {
#           "input_type": "text",
#           "out_type": "string",
#           "replace_placehold": "$GA4_PROPERTY_ID$",
#           "desc": "ga4 property id",
#           "doc": "https://github.com/surendranb/google-analytics-mcp#find-your-ga4-property-id",
#           "placeholder": "ga4 property id"
#         }
#       ]
#     }
#   ]
# }
#
# command_preq: python

# Check if FREVANA_HOME is set
if [ -z "$FREVANA_HOME" ]; then
    echo "Error: FREVANA_HOME environment variable is not set."
    exit 1
fi

# Set pip path with FREVANA_HOME prefix
PIP_CMD="$FREVANA_HOME/bin/pip"
GA4_CMD="$FREVANA_HOME/bin/ga4-mcp-server"

# Check if pip exists
if [ ! -f "$PIP_CMD" ]; then
    echo "Error: pip not found at $PIP_CMD"
    echo "Please ensure Python is properly installed in FREVANA_HOME."
    exit 1
fi

# Check if ga4-mcp-server is installed

echo "Installing google-analytics-mcp..."
$PIP_CMD install google-analytics-mcp

echo "MCP Google Analytics Server installed"

# "ga4-analytics": {
#       "command": "python3",
#       "args": ["-m", "ga4_mcp_server"],
#       "env": {
#         "GOOGLE_APPLICATION_CREDENTIALS": "/path/to/your/service-account-key.json",
#         "GA4_PROPERTY_ID": "123456789"
#       }
# }