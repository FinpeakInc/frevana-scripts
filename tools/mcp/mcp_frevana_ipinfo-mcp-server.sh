#!/bin/bash

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

# Let UVX install ipinfo-mcp-server

echo "MCP IPinfo is ready"
