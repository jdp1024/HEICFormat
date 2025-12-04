#!/bin/bash

# Create a distribution package for the HEIC Format plugin

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}HEIC Format Plugin - Distribution Packager${NC}"
echo "==========================================="
echo ""

# Check if plugin exists
if [ ! -d "build/HEICFormat.plugin" ]; then
    echo -e "${RED}Error: Plugin not found at build/HEICFormat.plugin${NC}"
    echo ""
    echo "Please build the plugin first:"
    echo -e "  ${YELLOW}./build.sh${NC}"
    exit 1
fi

# Create distribution directory
DIST_DIR="heic-format-distribution"
echo "Creating distribution package..."

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Copy plugin and installer
echo "Copying files..."
cp -R build/HEICFormat.plugin "$DIST_DIR/"
cp install.sh "$DIST_DIR/"
cp check_plugin.sh "$DIST_DIR/"
cp README.md "$DIST_DIR/"
cp CHANGELOG.md "$DIST_DIR/"

# Make scripts executable
chmod +x "$DIST_DIR/install.sh"
chmod +x "$DIST_DIR/check_plugin.sh"

# Get plugin version from Info.plist if available
VERSION="unknown"
if [ -f "build/HEICFormat.plugin/Contents/Info.plist" ]; then
    VERSION=$(defaults read "$(pwd)/build/HEICFormat.plugin/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "unknown")
fi

echo ""
echo "================================"
echo -e "${GREEN}✓ Distribution package created!${NC}"
echo "================================"
echo ""
echo -e "${BLUE}Location:${NC} ./${DIST_DIR}/"
echo -e "${BLUE}Contents:${NC}"
echo "  - HEICFormat.plugin (v${VERSION})"
echo "  - install.sh (installer)"
echo "  - check_plugin.sh (diagnostic tool)"
echo "  - README.md"
echo "  - CHANGELOG.md"
echo ""
echo "To distribute:"
echo "  1. Zip or tar the ${DIST_DIR} folder"
echo "  2. Users extract and run: ${YELLOW}sudo ./install.sh${NC}"
echo "  3. If issues occur, users can run: ${YELLOW}./check_plugin.sh${NC}"
echo ""
echo "To create an archive:"
echo "  ${YELLOW}zip -r heic-format-plugin.zip ${DIST_DIR}${NC}"
echo "  or"
echo "  ${YELLOW}tar czf heic-format-plugin.tar.gz ${DIST_DIR}${NC}"
echo ""

