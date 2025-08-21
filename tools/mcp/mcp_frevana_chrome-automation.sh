#!/bin/bash

# MCP Configuration for Chrome Automation
# {
#   "id": "mcp_frevana_chrome-automation",
#   "name": "Chrome Automation",
#   "category": "Automation",
#   "description": "Chrome Automation MCP powered by Playwright.\nhttps://github.com/JackZhao98/chrome-automation-mcp",
#   "author": "JackZhao98",
#   "homepage": "https://github.com/JackZhao98/chrome-automation-mcp",
#   "tags": ["automation", "chrome", "playwright"],
#   "config": [
#     {
#       "key": "command",
#       "value": "chrome-automation-mcp-lite",
#       "is_user_fill": false,
#       "fill_fields": []
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

# Set npm path with FREVANA_HOME prefix
NPM_CMD="$FREVANA_HOME/bin/npm"
CHROME_CMD="$FREVANA_HOME/bin/chrome-automation-mcp-lite"

# Check if npm exists
if [ ! -f "$NPM_CMD" ]; then
    echo "Error: npm not found at $NPM_CMD"
    echo "Please ensure Node.js is properly installed in FREVANA_HOME."
    exit 1
fi

# Check if chrome-automation-mcp-lite is installed
if [ ! -f "$CHROME_CMD" ]; then
    $NPM_CMD install -g chrome-automation-mcp-lite
fi

echo "Chrome Automation MCP installed"