#!/bin/bash

# MCP Configuration for Server Filesystem
# {
#   "id": "mcp_frevana_server-filesystem",
#   "name": "Server Filesystem",
#   "category": "Filesystem",
#   "description": "A server filesystem service that provides file system access capabilities",
#   "author": "ModelContextProtocol",
#   "homepage": "https://www.npmjs.com/package/@modelcontextprotocol/server-filesystem",
#   "tags": ["filesystem", "files", "storage"],
#   "config": [
#     {
#       "key": "command",
#       "value": "npx",
#       "is_user_fill": false,
#       "fill_fields": []
#     },
#     {
#       "key": "args",
#       "value": ["-y", "@modelcontextprotocol/server-filesystem", "$file_path$"],
#       "is_user_fill": true,
#       "fill_fields": [
#         {
#           "input_type": "text",
#           "out_type": "string",
#           "replace_placehold": "$file_path$",
#           "desc": "File system path",
#           "doc": "The root directory path that the filesystem server will have access to",
#           "placeholder": "/Users/username/Documents"
#         }
#       ]
#     },
#     {
#       "key": "env",
#       "value": {},
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

# Set npm/npx path with FREVANA_HOME prefix
NPM_CMD="$FREVANA_HOME/bin/npm"
NPX_CMD="$FREVANA_HOME/bin/npx"

# Check if npx exists
if [ ! -f "$NPX_CMD" ]; then
    echo "Error: npx not found at $NPX_CMD"
    echo "Please ensure Node.js is properly installed in FREVANA_HOME."
    exit 1
fi

# Pre-install @modelcontextprotocol/server-filesystem package to avoid installation delay during runtime
echo "Installing @modelcontextprotocol/server-filesystem package..."
$NPM_CMD install @modelcontextprotocol/server-filesystem || {
    echo "Warning: Failed to pre-install @modelcontextprotocol/server-filesystem package. It will be installed on first use."
}

echo "MCP Server Filesystem installed"
