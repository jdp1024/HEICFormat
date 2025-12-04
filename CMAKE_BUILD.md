# CMake Build System for HEICFormat

Detailed reference for the CMake build system.

## Overview

The CMake build system provides:

- **Automatic dependency detection** using pkg-config
- **Auto-detects host architecture** (Intel or Apple Silicon)
- **Static linking** for self-contained plugin
- **Simplified installation** to shared Adobe plugin directory
- **Cross-platform potential** (currently macOS only)

## Quick Reference

```bash
# Standard build and install
./build.sh
./install.sh

# Debug build
./build.sh --debug

# Force specific architecture (optional)
./build.sh --arch arm64    # Apple Silicon
./build.sh --arch x86_64   # Intel

# Clean build
./build.sh --clean

# Check installation
./check_plugin.sh
```

## CMake Configuration Options

### Standard CMake Options

| Option | Default | Description |
|--------|---------|-------------|
| `CMAKE_BUILD_TYPE` | Release | Build type: Release or Debug |
| `CMAKE_OSX_ARCHITECTURES` | x86_64 | Target architecture |
| `CMAKE_OSX_DEPLOYMENT_TARGET` | 10.13 | Minimum macOS version |

### Project-Specific Options

| Option | Default | Description |
|--------|---------|-------------|
| `CMAKE_OSX_ARCHITECTURES` | Auto-detected | Target architecture (arm64 or x86_64) |
| `PHOTOSHOP_SDK_PATH` | `../photoshopsdk/pluginsdk/photoshopapi` | Path to Adobe Photoshop SDK |

**Notes:**
- Architecture is automatically detected (Intel or Apple Silicon)
- SDK path expects the standard Adobe SDK structure
- Installation goes to shared Adobe plugin directory

### Example Configurations

#### Debug Build

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
```

#### Force Specific Architecture (Optional)

By default, builds for host architecture. To force a specific architecture:

```bash
# Force Apple Silicon (arm64)
cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build build

# Force Intel (x86_64)
cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES=x86_64
cmake --build build
```

#### Custom SDK Location

If your SDK is in a different location or has a different name:

```bash
# SDK extracted as "pluginsdk"
cmake -B build \
    -DPHOTOSHOP_SDK_PATH=~/src/pluginsdk
cmake --build build

# SDK in custom location
cmake -B build \
    -DPHOTOSHOP_SDK_PATH=/path/to/your/photoshop-sdk
cmake --build build
```

#### Installation to Shared Adobe Directory

Installation goes to the shared Adobe plugin directory that all Photoshop versions recognize:

```bash
cmake -B build
cmake --build build
sudo cmake --install build
```

Installs to: `/Library/Application Support/Adobe/Plug-Ins/CC/File Formats/`

## Dependency Detection

The CMake system uses `pkg-config` to locate dependencies. Here's how each library is found:

### libheif

```bash
pkg-config --modversion libheif
pkg-config --libs --static libheif
```

If not found, ensure libheif is installed:
```bash
brew install libheif
```

### x265

```bash
pkg-config --modversion x265
pkg-config --libs --static x265
```

If not found:
```bash
brew install x265
```

### LittleCMS 2

```bash
pkg-config --modversion lcms2
pkg-config --libs --static lcms2
```

Standard installation:
```bash
brew install little-cms2
```

### LittleCMS 2 Fast Float Plugin (Optional)

The fast_float plugin is an **optional optimization** that provides faster color conversions. The plugin works perfectly without it.

**Homebrew's lcms2 is sufficient** - no need to build from source unless you want the optimization.

If you want the fast_float optimization, build from source:
```bash
cd ~/Downloads
curl -L -O https://downloads.sourceforge.net/project/lcms/lcms/2.16/lcms2-2.16.tar.gz
tar xzf lcms2-2.16.tar.gz
cd lcms2-2.16
./configure --with-fastfloat
make
sudo make install
```

The CMake system automatically checks for it in:
1. `/opt/homebrew/lib/liblcms2_fast_float.a` (Homebrew ARM64)
2. `/usr/local/lib/liblcms2_fast_float.a` (Homebrew Intel)
3. Same directory as `liblcms2.a`
4. `~/lib/liblcms2_fast_float.a`

## Build Targets

### Main Target: HEICFormat

The main plugin bundle. Builds all source files and creates the `.plugin` bundle.

```bash
cmake --build build --target HEICFormat
```

### Rez Resources Target

Compiles the resource file (`HEICFormat.r`) using the Rez compiler.

```bash
cmake --build build --target RezResources
```

This target is automatically executed as a dependency of the main target.

## Installation

### Using Install Script (Recommended)

```bash
./install.sh
```

Installs to the shared Adobe plugin directory:
```
/Library/Application Support/Adobe/Plug-Ins/CC/File Formats/HEICFormat.plugin
```

This location is automatically recognized by **all Adobe Photoshop versions** (2020-2026+).

Features:
- Creates plugin directory if needed
- Removes old plugin version
- Sets correct permissions
- Code signs with runtime for Apple Silicon
- Works for all Photoshop versions with single install

### Using CMake Install

```bash
sudo cmake --install build
```

### Manual Installation

```bash
sudo cp -R build/HEICFormat.plugin "/Library/Application Support/Adobe/Plug-Ins/CC/File Formats/"
sudo xattr -cr "/Library/Application Support/Adobe/Plug-Ins/CC/File Formats/HEICFormat.plugin"
sudo chmod -R a+rX "/Library/Application Support/Adobe/Plug-Ins/CC/File Formats/HEICFormat.plugin"
sudo codesign --force --deep --sign - --options runtime "/Library/Application Support/Adobe/Plug-Ins/CC/File Formats/HEICFormat.plugin"
```

## Troubleshooting

### CMake can't find dependencies

**Error:**
```
Package 'libheif' not found
```

**Solution:**
Ensure pkg-config can find the library:
```bash
pkg-config --modversion libheif
# If this fails, the library isn't properly installed or pkg-config can't find it

# Check PKG_CONFIG_PATH
echo $PKG_CONFIG_PATH

# For Homebrew on Apple Silicon:
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:$PKG_CONFIG_PATH"

# For Homebrew on Intel:
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
```

### Adobe Photoshop SDK not found

**Error:**
```
Adobe Photoshop SDK not found at /path/to/photoshopsdk
```

**Solution:**
1. Download the SDK from https://console.adobe.io/downloads
2. Extract to `~/src/photoshopsdk` (or rename the extracted folder)
3. Or specify custom path:
```bash
# If SDK extracted as "pluginsdk"
cmake -B build -DPHOTOSHOP_SDK_PATH=~/src/pluginsdk

# Or for custom location
cmake -B build -DPHOTOSHOP_SDK_PATH=/your/custom/path
```

**Note:** The SDK archive may extract with different names like `pluginsdk` or `PS_SDK`. Either rename it to `photoshopsdk` or use the `-DPHOTOSHOP_SDK_PATH` option.

### Fast Float Plugin not found

**Message:**
```
liblcms2_fast_float not found - using standard lcms2 (plugin works fine)
```

**Solution:**
This is **not an error** - the plugin works perfectly without it. The fast_float plugin is an optional optimization.

If you want the optimization, build lcms2 from source:
```bash
cd ~/Downloads
curl -L -O https://downloads.sourceforge.net/project/lcms/lcms/2.16/lcms2-2.16.tar.gz
tar xzf lcms2-2.16.tar.gz
cd lcms2-2.16
./configure --with-fastfloat
make
sudo make install
```

### Rez not found

**Warning:**
```
Rez not found. Resource file will not be compiled.
```

**Solution:**
Rez should be included with Xcode Command Line Tools:
```bash
xcode-select --install
# Then verify:
which Rez
```

### Plugin not appearing in Photoshop

1. **Check installation:**
   ```bash
   ls -la "/Applications/Adobe Photoshop 2024/Plug-ins/HEICFormat.plugin"
   ```

2. **Check permissions:**
   ```bash
   xattr -l "/Applications/Adobe Photoshop 2024/Plug-ins/HEICFormat.plugin"
   # Should show no quarantine attributes
   ```

3. **Re-apply permissions:**
   ```bash
   sudo xattr -cr "/Applications/Adobe Photoshop 2024/Plug-ins/HEICFormat.plugin"
   sudo chmod -R a+rX "/Applications/Adobe Photoshop 2024/Plug-ins/HEICFormat.plugin"
   sudo chmod a+x "/Applications/Adobe Photoshop 2024/Plug-ins/HEICFormat.plugin/Contents/MacOS/HEICFormat"
   ```

4. **Restart Photoshop completely** (not just close windows)

5. **Check Console.app** for errors related to plugin loading

## Directory Structure

The build creates the following structure:

```
build/
├── CMakeCache.txt
├── CMakeFiles/
├── HEICFormat.plugin/
│   └── Contents/
│       ├── Info.plist
│       ├── MacOS/
│       │   └── HEICFormat       # Main executable
│       └── Resources/
│           ├── HEICFormat.rsrc  # Compiled resources
│           └── HEIC_UI.xib      # UI definition
└── HEICFormat.rsrc              # Temporary resource file
```

## Advanced Usage

### Building with Ninja

For faster builds, use Ninja instead of Make:

```bash
brew install ninja
cmake -B build -G Ninja
cmake --build build
```

### Verbose Build Output

```bash
cmake --build build --verbose
```

### Build Only (No Install)

```bash
./build.sh
# Plugin is in: build/HEICFormat.plugin
```

### Custom Compiler

```bash
export CC=/usr/bin/clang
export CXX=/usr/bin/clang++
cmake -B build
```

### Build Universal Binary (Optional)

To create a binary that works on both Intel and Apple Silicon, you need dependencies built for both architectures. This is complex and usually unnecessary since the plugin auto-detects architecture.


## See Also

- [README.md](README.md) - Main project documentation
- [SDK_SETUP.md](SDK_SETUP.md) - Adobe Photoshop SDK setup guide
- [CMakeLists.txt](CMakeLists.txt) - CMake configuration file

