#!/bin/bash

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

echo "MCP Stripe Server installed"
