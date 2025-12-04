#!/bin/bash

# Build script for HEICFormat Photoshop Plugin
# This script simplifies the CMake build process

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}HEICFormat Build Script${NC}"
echo "========================"
echo ""

# Default values
BUILD_TYPE="Release"
BUILD_DIR="build"
FORCE_ARCH=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        --arch)
            FORCE_ARCH="$2"
            shift 2
            ;;
        --clean)
            echo -e "${YELLOW}Cleaning build directory...${NC}"
            rm -rf "$BUILD_DIR"
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --debug                 Build in Debug mode (default: Release)"
            echo "  --arch ARCH            Force specific architecture (arm64, x86_64)"
            echo "                         By default, builds for host architecture"
            echo "  --clean                 Clean build directory before building"
            echo "  --help                  Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Build for host architecture"
            echo "  $0 --debug                            # Build debug version"
            echo "  $0 --arch arm64                       # Force build for Apple Silicon"
            echo "  $0 --arch x86_64                      # Force build for Intel"
            echo ""
            echo "Note: Installation will automatically detect and install to all"
            echo "      Adobe Photoshop versions found on your system."
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check for required tools
echo "Checking for required tools..."

if ! command -v cmake &> /dev/null; then
    echo -e "${RED}Error: CMake is not installed${NC}"
    echo "Install it with: brew install cmake"
    exit 1
fi

if ! command -v pkg-config &> /dev/null; then
    echo -e "${RED}Error: pkg-config is not installed${NC}"
    echo "Install it with: brew install pkg-config"
    exit 1
fi

echo -e "${GREEN}✓ All required tools found${NC}"
echo ""

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure CMake
echo "Configuring CMake..."
CMAKE_ARGS=(
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
)

if [ -n "$FORCE_ARCH" ]; then
    echo "Forcing architecture: $FORCE_ARCH"
    CMAKE_ARGS+=(-DCMAKE_OSX_ARCHITECTURES="$FORCE_ARCH")
fi

cmake .. "${CMAKE_ARGS[@]}"

if [ $? -ne 0 ]; then
    echo -e "${RED}CMake configuration failed!${NC}"
    exit 1
fi

echo ""
echo "Building..."
cmake --build . --config "$BUILD_TYPE" -j$(sysctl -n hw.ncpu)

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Build successful!${NC}"
echo ""
echo "Plugin built at: $(pwd)/HEICFormat.plugin"
echo ""
echo "To install to all Photoshop versions, run:"
echo -e "  ${YELLOW}./install.sh${NC}"
echo ""
echo "Or use CMake install:"
echo -e "  ${YELLOW}sudo cmake --install .${NC}"
echo ""

