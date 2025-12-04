# HEIC Format Plug-in for Adobe Photoshop

**Version 0.1.2**

A professional-grade plug-in for Adobe Photoshop that adds support for saving documents in HEIC format with automatic transparency detection and color management.

## Features

This plugin provides **enhanced HEIC export** capabilities for Photoshop (Photoshop already has built-in HEIC read support since CC 2018):

- ✅ **HEIC/HEIF Export** - Save Photoshop documents as modern HEIC files
- ✅ **Per-Export Transparency Control** - Choose to save or flatten transparency each time you export
- ✅ **Adjustable Quality** - Fine-tune compression from 1-100
- ✅ **Color Management** - Embed ICC profiles or convert to sRGB
- ✅ **Metadata Preservation** - Optionally save EXIF and XMP data
- ✅ **Universal Binary** - Works on both Intel and Apple Silicon Macs
- ✅ **All Photoshop Versions** - Single installation for PS 2020-2026+
- ✅ **Stable & Crash-Free** - Proper manual reference counting (MRC) memory management

## Quick Start

```bash
# Install dependencies
brew install cmake pkg-config libheif x265 little-cms2

# Note: lcms2_fast_float plugin is optional (optimization only)
# If you want the fast_float optimization, build from source:
# curl -L -O https://downloads.sourceforge.net/project/lcms/lcms/2.16/lcms2-2.16.tar.gz
# tar xzf lcms2-2.16.tar.gz && cd lcms2-2.16
# ./configure --with-fastfloat && make && sudo make install

# Download Adobe Photoshop SDK from https://console.adobe.io/downloads
# Extract to ~/src/photoshopsdk

# Build and install
cd ~/src/HEICFormat
./build.sh
sudo ./install.sh
```

Restart Photoshop and look for **"HEIC Format"** in **File → Save As**.

## Distribution Mode

The `install.sh` script is **smart** and can find the plugin in multiple locations:

1. **Development mode**: `build/HEICFormat.plugin` (when building from source)
2. **Bundled mode**: `HEICFormat.plugin` in same directory as `install.sh`
3. **Simple mode**: `HEICFormat.plugin` in current directory

### Distributing Pre-built Plugin

To distribute the plugin:

```bash
# Create distribution folder
mkdir heic-plugin-distribution
cp -R build/HEICFormat.plugin heic-plugin-distribution/
cp install.sh heic-plugin-distribution/

# Users can then run:
cd heic-plugin-distribution
sudo ./install.sh
```

The installer will automatically find and install the bundled plugin.

## Usage

### Basic Export

1. **File → Save As**
2. Choose **"HEIC Format"** from the format dropdown
3. Click **Save**
4. Adjust quality and options in the dialog
5. Click **OK**

### Saving with Transparency

The plugin intelligently handles transparency based on your document:

**Documents WITH Transparency:**
1. **File → Save As**
2. Choose **"HEIC Format"**
3. Click **Save**
4. In the export dialog, you'll see **"Save Transparency"** checkbox
   - **Checked** (default): Transparency is saved in the HEIC file
   - **Unchecked**: Image is flattened to RGB, no transparency saved
5. Click **OK**

**Documents WITHOUT Transparency (flattened):**
- The "Save Transparency" checkbox will be **hidden**
- Image is automatically saved as RGB only
- No transparency option shown since none is available

**Note:** The plugin automatically detects whether your document has transparency and only shows the option when it's relevant.

### Export Options

- **Quality** (1-100) - Controls compression level
- **Save Transparency** - Include alpha channel when present (per-export, default: ON)
- **Save EXIF metadata** - Preserve camera data
- **Save XMP metadata** - Preserve Photoshop metadata
- **Convert to sRGB** - Override embedded color profiles
- **Reveal in Finder** - Open file location after saving
- **Don't ask every time** - Remember settings (access via Help → About Plug-ins)

## Building from Source

### Prerequisites

- **Adobe Photoshop SDK** - Download from [Adobe Console](https://console.adobe.io/downloads)
- **libheif** - HEIF encoder/decoder library
- **x265** - HEVC video codec library
- **LittleCMS 2** - Color management with fast float plugin
- **CMake 3.15+** - Build system
- **Xcode Command Line Tools** - C++ compiler

### Step-by-Step Build

#### 1. Install Build Tools

```bash
brew install cmake pkg-config
```

#### 2. Install Base Dependencies

```bash
brew install libheif x265
```

#### 3. Install LittleCMS 2

**Option A: Use Homebrew (Recommended)**
```bash
brew install little-cms2
```
The plugin works perfectly with Homebrew's lcms2. The fast_float plugin is optional and only provides a minor performance optimization.

**Option B: Build with Fast Float Plugin (Optional Optimization)**
If you want the fast_float optimization plugin:
```bash
cd ~/Downloads
curl -L -O https://downloads.sourceforge.net/project/lcms/lcms/2.16/lcms2-2.16.tar.gz
tar xzf lcms2-2.16.tar.gz
cd lcms2-2.16
./configure --with-fastfloat
make
sudo make install
```
Note: This is optional - the plugin works fine without it.

#### 4. Install Adobe Photoshop SDK

Download from [Adobe Console](https://console.adobe.io/downloads) and extract:

```bash
mkdir -p ~/src
cd ~/src
# Extract your downloaded SDK here
```

Expected structure:
```
~/src/
├── HEICFormat/                  # This repository
└── photoshopsdk/                # Adobe SDK
    └── pluginsdk/
        └── photoshopapi/
            ├── photoshop/
            ├── pica_sp/
            └── ...
```

If your SDK is elsewhere:
```bash
cmake -B build -DPHOTOSHOP_SDK_PATH=/path/to/sdk/pluginsdk/photoshopapi
```

#### 5. Build and Install

```bash
cd ~/src/HEICFormat
./build.sh
sudo ./install.sh
```

**Installation location:**
```
/Library/Application Support/Adobe/Plug-Ins/CC/File Formats/HEICFormat.plugin
```

This location works for **all Adobe Photoshop versions** (2020-2026+).

### Build Options

```bash
./build.sh --help        # Show all options
./build.sh --debug       # Build with debug symbols
./build.sh --arch arm64  # Force architecture
./build.sh --clean       # Clean build
```

### Verification

```bash
./check_plugin.sh        # Verify installation and configuration
```

## Troubleshooting

### Plugin Not Appearing

1. **Verify installation:**
   ```bash
   ./check_plugin.sh
   ```

2. **Clear Photoshop cache:**
   ```bash
   rm -rf ~/Library/Caches/Adobe/Photoshop*/PluginCache
   ```

3. **Completely quit and restart Photoshop** (Cmd+Q, not just close windows)

4. **Check installation:**
   ```bash
   ls -la "/Library/Application Support/Adobe/Plug-Ins/CC/File Formats/HEICFormat.plugin"
   ```

### Options Dialog Always Appears

If you want to skip the options dialog on every save:

1. **Help → About Plug-ins → HEIC Format**
2. Check **"Don't ask me every time"**
3. Click **OK**

To re-enable the dialog, open About Plug-ins and uncheck it.

### Debugging

Check the debug log:
```bash
cat /tmp/heic.log
```

The log shows:
- Plugin initialization
- Alpha channel detection
- Quality settings
- Errors and warnings

## Technical Details

### Memory Management

The plugin uses **Manual Reference Counting (MRC)** for Objective-C code with:
- Proper autorelease pool management
- Explicit retain/release of NIB objects
- Exception-safe cleanup with @try/@catch/@finally

### Transparency Detection

The plugin automatically detects transparency in your document:

```cpp
// Photoshop provides RGBA data when transparency is present
const bool save_alpha = (formatRecord->planes >= 4);

// Creates appropriate HEIF image format
heif_image_create(..., 
    save_alpha ? heif_chroma_interleaved_RGBA 
               : heif_chroma_interleaved_RGB, 
    &image);
```

Transparency is handled automatically based on the image content.

### Color Management

- Embeds ICC color profiles by default
- Can convert to sRGB (useful for web/iOS compatibility)
- Uses LittleCMS 2 with fast float plugin for performance

## Additional Documentation

- [CMAKE_BUILD.md](CMAKE_BUILD.md) - Detailed CMake reference
- [SDK_SETUP.md](SDK_SETUP.md) - Adobe SDK setup guide
- [CHANGELOG.md](CHANGELOG.md) - Version history

## Troubleshooting

If the plugin doesn't appear in Photoshop:

1. **Run the diagnostic tool:**
   ```bash
   ./check_plugin.sh
   ```
   This will verify installation, check code signing, and suggest fixes.

2. **Clear plugin cache:**
   ```bash
   rm -rf ~/Library/Caches/Adobe/Photoshop*/PluginCache
   rm -rf ~/Library/Caches/com.adobe.Photoshop*/
   ```

3. **Restart Photoshop** completely (Cmd+Q, then relaunch)

4. **Check Console.app** for plugin loading errors

## Known Limitations

- **macOS only** - Windows version not implemented
- **Export only** - Plugin provides write support; Photoshop has built-in read support (CC 2018+)
- **Default x265 settings** - Not customizable
- **Not scriptable** - No AppleScript/JavaScript support yet

### Note on HEIC Reading

Photoshop can already **open and read HEIC files** natively:
- **macOS:** Photoshop CC 2018+ (v19.0, October 2017) with macOS High Sierra 10.13+
- **Windows:** Photoshop CC 2021+ (v22) with Microsoft HEVC/HEIF codecs from the Store

This plugin focuses on providing **enhanced export capabilities** with fine-grained quality control and transparency handling.

## Compatibility

- **macOS:** 10.13 (High Sierra) or later
- **Photoshop:** CS6 through 2026+
- **Architectures:** Intel (x86_64) and Apple Silicon (arm64)

## License

**GPL v3** - Written by jdp, 2021-2025

## Credits

Built with:
- [libheif](https://github.com/strukturag/libheif) - HEIF encoder/decoder
- [x265](https://www.videolan.org/developers/x265.html) - HEVC codec
- [LittleCMS](https://github.com/mm2/Little-CMS) - Color management
- Adobe Photoshop SDK

## Links

- **Download Photoshop SDK:** https://console.adobe.io/downloads
- **LittleCMS Fast Float Plugin:** https://www.littlecms.com/plugin
- **libheif:** https://github.com/strukturag/libheif
