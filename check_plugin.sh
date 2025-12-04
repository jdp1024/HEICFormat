#!/bin/bash

# Diagnostic script for HEICFormat plugin

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}HEICFormat Plugin Diagnostic Tool${NC}"
echo "===================================="
echo ""

PLUGIN_PATH="/Library/Application Support/Adobe/Plug-Ins/CC/File Formats/HEICFormat.plugin"

# Check if plugin exists
if [ ! -d "$PLUGIN_PATH" ]; then
    echo -e "${RED}✗ Plugin not installed${NC}"
    echo "  Expected location: $PLUGIN_PATH"
    exit 1
else
    echo -e "${GREEN}✓ Plugin exists${NC}"
fi

# Check binary
BINARY="$PLUGIN_PATH/Contents/MacOS/HEICFormat"
if [ -x "$BINARY" ]; then
    echo -e "${GREEN}✓ Binary is executable${NC}"
    file "$BINARY" | sed 's/^/  /'
else
    echo -e "${RED}✗ Binary is not executable${NC}"
fi

# Check architecture
ARCH=$(file "$BINARY" | grep -o "arm64\|x86_64")
echo -e "${GREEN}✓ Architecture: ${ARCH}${NC}"

# Check Info.plist
BUNDLE_TYPE=$(defaults read "$PLUGIN_PATH/Contents/Info" CFBundlePackageType 2>/dev/null)
BUNDLE_EXEC=$(defaults read "$PLUGIN_PATH/Contents/Info" CFBundleExecutable 2>/dev/null)
if [ "$BUNDLE_TYPE" == "8BIF" ]; then
    echo -e "${GREEN}✓ Bundle type: $BUNDLE_TYPE (Format plugin)${NC}"
else
    echo -e "${RED}✗ Bundle type: $BUNDLE_TYPE (should be 8BIF)${NC}"
fi

if [ "$BUNDLE_EXEC" == "HEICFormat" ]; then
    echo -e "${GREEN}✓ Bundle executable: $BUNDLE_EXEC${NC}"
else
    echo -e "${RED}✗ Bundle executable: $BUNDLE_EXEC${NC}"
fi

# Check code signature
echo -e "${BLUE}Code Signature:${NC}"
codesign -dv "$PLUGIN_PATH" 2>&1 | grep -E "Identifier|Format|Signature|Runtime" | sed 's/^/  /'

# Check for quarantine
XATTRS=$(xattr "$PLUGIN_PATH" 2>/dev/null)
if [ -z "$XATTRS" ]; then
    echo -e "${GREEN}✓ No quarantine attributes${NC}"
else
    echo -e "${YELLOW}⚠ Extended attributes found:${NC}"
    echo "$XATTRS" | sed 's/^/  /'
fi

# Check dependencies
echo ""
echo -e "${BLUE}Dependencies:${NC}"
NON_SYSTEM=$(otool -L "$BINARY" | grep -v "System\|usr/lib" | tail -n +2)
if [ -z "$NON_SYSTEM" ]; then
    echo -e "${GREEN}✓ Only system libraries (no external dependencies)${NC}"
else
    echo -e "${YELLOW}⚠ External dependencies found:${NC}"
    echo "$NON_SYSTEM" | sed 's/^/  /'
fi

# Check resources
echo ""
echo -e "${BLUE}Resources:${NC}"
if [ -f "$PLUGIN_PATH/Contents/Resources/HEICFormat.rsrc" ]; then
    echo -e "${GREEN}✓ HEICFormat.rsrc present${NC}"
    
    # Check for ARM64 code descriptor
    if strings "$PLUGIN_PATH/Contents/Resources/HEICFormat.rsrc" | grep -q "ma64"; then
        echo -e "${GREEN}✓ ARM64 code descriptor (ma64) found${NC}"
    else
        echo -e "${RED}✗ ARM64 code descriptor (ma64) missing${NC}"
    fi
    
    # Check for Intel code descriptor
    if strings "$PLUGIN_PATH/Contents/Resources/HEICFormat.rsrc" | grep -q "mi64"; then
        echo -e "${GREEN}✓ Intel code descriptor (mi64) found${NC}"
    else
        echo -e "${YELLOW}⚠ Intel code descriptor (mi64) missing${NC}"
    fi
else
    echo -e "${RED}✗ HEICFormat.rsrc missing${NC}"
fi

if [ -f "$PLUGIN_PATH/Contents/Resources/HEIC_UI.xib" ]; then
    echo -e "${GREEN}✓ HEIC_UI.xib present${NC}"
else
    echo -e "${RED}✗ HEIC_UI.xib missing${NC}"
fi

# Check Photoshop installations
echo ""
echo -e "${BLUE}Adobe Photoshop Installations:${NC}"
for ps in /Applications/Adobe\ Photoshop*; do
    if [ -d "$ps" ]; then
        echo "  - $(basename "$ps")"
    fi
done

# Suggest next steps
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Completely quit Photoshop (Cmd+Q)"
echo "2. Clear plugin cache:"
echo "   rm -rf ~/Library/Caches/Adobe/Photoshop*/PluginCache"
echo "   rm -rf ~/Library/Caches/com.adobe.Photoshop*/"
echo ""
echo "3. Start Photoshop and check:"
echo "   - Help > About Plug-ins (look for 'HEIC Format')"
echo "   - File > Save As (look for 'HEIC Format' in format list)"
echo ""
echo "4. If still not visible, check Console.app for errors:"
echo "   - Open Console.app"
echo "   - Filter for 'Photoshop'"
echo "   - Launch Photoshop and look for plugin loading errors"
echo ""

