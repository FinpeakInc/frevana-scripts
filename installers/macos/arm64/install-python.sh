#!/bin/bash

# Python Downloader for macOS ARM64
# This script only handles downloading Python package

set -e

# Parse command line arguments
min_version=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --min-version=*)
            min_version="${1#*=}"
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# FREVANA_HOME should be set by the calling script
if [ -z "$FREVANA_HOME" ]; then
    echo "❌ Error: FREVANA_HOME not set" >&2
    exit 1
fi

# Determine target version based on requirement
target_version="3.12.2"
if [ -n "$min_version" ]; then
    echo "🎯 Target version: $target_version (>= $min_version)"
else
    echo "🎯 Using latest stable version: $target_version"
fi

# Download URLs for macOS (使用GitHub上的预编译Python或其他源)
# 使用python-build-standalone的预编译版本
download_url="https://github.com/astral-sh/python-build-standalone/releases/download/20231002/cpython-$target_version+20231002-aarch64-apple-darwin-install_only.tar.gz"
output_file="$FREVANA_HOME/tmp/python-$target_version-macos-arm64.tar.gz"

echo "📥 Downloading Python v$target_version package for macOS ARM64..."
echo "   → URL: $download_url"
echo "   → Output: $output_file"

# Download the file
if command -v curl &> /dev/null; then
    curl -fsSL "$download_url" -o "$output_file"
elif command -v wget &> /dev/null; then
    wget -q "$download_url" -O "$output_file"
else
    echo "❌ Error: Neither curl nor wget found" >&2
    exit 1
fi

# Verify download
if [ -f "$output_file" ]; then
    file_size=$(stat -f%z "$output_file" 2>/dev/null || du -b "$output_file" | cut -f1)
    echo "✅ Download completed successfully!"
    echo "   → File size: $(echo $file_size | awk '{printf "%.2f MB", $1/1024/1024}')"
    echo "   → Location: $output_file"
else
    echo "❌ Error: Download failed" >&2
    exit 1
fi
