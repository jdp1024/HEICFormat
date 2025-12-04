# Changelog

## Version 0.1.2 - December 3, 2025

### Transparency Compositing Fix

- **Fixed black box issue** - When "Save Transparency" is unchecked, layered PSD files now properly composite against white background instead of showing black boxes
- **Correct transparency matting** - Plugin now sets `transparencyMatting = 3` (white matte) when transparency is disabled, ensuring Photoshop composites layers properly
- **Per-export transparency control working correctly** - Users can now save layered PSDs without transparency and get properly flattened results

### Technical Fixes

- **Fixed compilation errors** - Resolved template issues with HEICParam struct handling
- **Correct field usage** - Changed `pluginData` to `revertInfo` for proper Photoshop SDK compliance
- **Updated function signatures** - Fixed HEIC_UI function to properly pass options between dialog and export

---

## Version 0.1.1 - December 1, 2025

### Smart Installer & Transparency Control

### Installer Improvements

- **Smart Plugin Detection** - `install.sh` now automatically finds the plugin in multiple locations:
  - `build/HEICFormat.plugin` (development mode - building from source)
  - Same directory as `install.sh` (distribution mode - bundled with installer)
  - Current directory (simple distribution mode)
- **Easy Distribution** - Plugin can now be distributed as a simple folder with `HEICFormat.plugin` and `install.sh` together
- **Better Error Messages** - Shows all searched locations if plugin is not found

### Per-Export Transparency Control

- **Per-Export Transparency Toggle** - Choose whether to save transparency each time you export
  - New "Save Transparency" checkbox in the export dialog
  - Checked (default): Saves transparency when document has alpha channels
  - Unchecked: Flattens image to RGB, no transparency saved
  - Choice is made per-export, not saved as a global preference
  - Gives users full control on every save

### UI Changes

- Replaced "Auto-detect Transparency" preference with per-export "Save Transparency" option
- Checkbox appears in export dialog (File → Save As)
- **Smart visibility:** Checkbox is automatically hidden when document has no transparency
- NOT in preferences dialog (Help → About Plug-ins) - it's a per-export decision

### Technical Details

- Added `saveTransparency` field to `HEICParam` struct (transient, not persisted)
- Added `hasAlpha` field to detect transparency availability
- UI controller checks `formatRecord->planes >= 4` to determine alpha presence
- Checkbox is hidden and disabled when no alpha is available
- Updated XIB file with export-time checkbox control
- Modified export logic to respect per-export choice
- Default: Save transparency ON (when available)
- Never saves transparency if Photoshop doesn't provide it

### Memory Management & Alpha Channel Detection

#### Critical Fixes

- **Fixed memory management crashes** - Complete rewrite of MRC (Manual Reference Counting) handling
  - Added proper autorelease pool in `HEIC_UI()` function
  - Proper retention and release of NIB top-level objects
  - Exception-safe cleanup with @try/@catch/@finally blocks
  - Fixed memory leaks in `NSUserDefaults` handling
  - Plugin no longer crashes when clicking OK/Cancel in dialogs

### Major Features

- **Automatic transparency detection** - Plugin automatically handles transparency
  - Removed manual alpha selector from UI (simplified workflow)
  - Automatically detects when transparency is present in the document
  - Only saves transparency when actually present in the image
  - Follows standard Photoshop plugin conventions (like PNG, TIFF, etc.)
  - Smart handling: only includes transparency when needed

### Code Quality Improvements

- **Modernized Cocoa APIs:**
  - `NSControlStateValueOn/Off` vs deprecated `NSOnState/NSOffState`
  - `NSModalResponseContinue` vs deprecated `NSRunContinuesResponse`
  - `typedef NS_ENUM` for better Objective-C integration
- **Modernized C++ code:**
  - Converted `NULL` → `nullptr` throughout (5+ instances)
  - Modern CoreFoundation: `CFURLCopyFileSystemPath` vs deprecated `CFURLCopyPath`
  - Proper `CFRelease()` calls to prevent memory leaks
  - Suppressed unavoidable deprecation warnings with pragmas
- **Code cleanup:**
  - Added comprehensive debug logging (errors only in production)
  - Clean error handling and validation
  - Exception-safe patterns with @try/@catch/@finally
  - Proper MRC memory management patterns
- **Documentation:**
  - Consolidated and cleaned up documentation
  - Removed temporary debug scripts
  - Clarified that Photoshop has built-in HEIC read support (CC 2018+)

### Removed

- Manual "Alpha" radio buttons in options dialog
- `opt.alpha` preference setting
- Temporary debug scripts (check_log.sh, reset_preferences.sh, etc.)
- Redundant documentation files

### Technical Details

```cpp
// Transparency detection logic
const bool save_alpha = (formatRecord->planes >= 4);
// Photoshop provides RGBA data when transparency is present
```

Memory management:
```objective-c
// Proper MRC pattern
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
// ... load NIB and run dialog ...
[controller release];
[pool drain];
```

### CMake Build System & Apple Silicon Support

#### Major Changes

- **Added CMake build system** - Modern, cross-platform build configuration
- **Apple Silicon (ARM64) support** - Fixed plugin to work on M1/M2/M3 Macs
- **Automatic architecture detection** - Builds for host architecture automatically
- **Static linking** - All dependencies statically linked for self-contained plugin
- **Shared plugin location** - Installs to `/Library/Application Support/Adobe/Plug-Ins/CC/File Formats/`
  - Works with all Photoshop versions (2020-2026+) from single installation

### Fixed Issues

1. **ARM64 Code Descriptor** - Added `CodeMacARM64` to resource file for Photoshop 2025+ compatibility
2. **Dynamic Library Dependencies** - Changed to static linking to eliminate Homebrew runtime dependencies
3. **Code Signing** - Added proper ad-hoc code signing with runtime hardening for Apple Silicon
4. **Info.plist** - Fixed template variable expansion issues

### New Files

- `CMakeLists.txt` - CMake build configuration
- `build.sh` - Simple build script with options
- `install.sh` - Installation script for shared plugin directory
- `check_plugin.sh` - Diagnostic tool to verify plugin installation
- `Info.plist` - Proper bundle metadata file
- `.gitignore` - Build artifacts exclusion

### Documentation

- `README.md` - Comprehensive quick start and build instructions
- `CMAKE_BUILD.md` - Detailed CMake reference and troubleshooting
- `SDK_SETUP.md` - Adobe Photoshop SDK setup guide

### Build Features

- Auto-detects host architecture (Intel or Apple Silicon)
- Uses pkg-config for dependency detection
- Compiles SDK sources as Objective-C++ where needed
- Includes Rez resource compilation
- Post-install permission fixing

### Compatibility

- **macOS**: 10.13+ (High Sierra and later)
- **Architectures**: Intel (x86_64) and Apple Silicon (arm64)
- **Photoshop**: CC 2020 through 2026+ (all versions)

### Dependencies

- libheif (statically linked)
- x265 (statically linked)
- LittleCMS 2 with fast float plugin (statically linked)
- System frameworks only at runtime

---

## Previous Versions

See git history for changes prior to CMake migration.

