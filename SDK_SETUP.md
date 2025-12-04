# Adobe Photoshop SDK Setup

This guide helps you set up the Adobe Photoshop SDK correctly for building HEICFormat.

## Download the SDK

1. Go to [Adobe Console Downloads](https://console.adobe.io/downloads)
2. Sign in with your Adobe ID
3. Download the **Photoshop SDK** (e.g., `adobe_photoshop_sdk_2024_mac_v1.zip`)

## Extract

The SDK typically extracts as a folder containing `pluginsdk/photoshopapi/`:

```bash
cd ~/Downloads
unzip adobe_photoshop_sdk_*.zip

# Move to ~/src
mkdir -p ~/src
mv adobe_photoshop_sdk_* ~/src/photoshopsdk
```

Or if the archive structure is different, just ensure the path to `photoshopapi` is correct.

### Verify the Structure

After extraction, you should have:

```
~/src/photoshopsdk/
└── pluginsdk/
    ├── photoshopapi/
    │   ├── photoshop/        # Photoshop API headers
    │   ├── pica_sp/          # PICA Suite headers
    │   └── resources/
    └── samplecode/
        └── common/
            ├── includes/
            ├── resources/
            └── sources/
```

### Custom SDK Location

If your SDK is elsewhere, specify the path to `photoshopapi`:

```bash
cmake -B build -DPHOTOSHOP_SDK_PATH=/path/to/sdk/pluginsdk/photoshopapi
```

## Standard Directory Layout

```
~/src/
├── HEICFormat/                    # This repository
└── photoshopsdk/                  # Adobe Photoshop SDK
    └── pluginsdk/
        └── photoshopapi/
            ├── photoshop/
            ├── pica_sp/
            └── resources/
```

CMake automatically looks for the SDK at `../photoshopsdk/pluginsdk/photoshopapi`.

## Troubleshooting

### Error: SDK not found

```
CMake Error: Adobe Photoshop SDK not found at ~/src/photoshopsdk
```

**Solution:**
1. Check the SDK is actually extracted:
   ```bash
   ls ~/src/photoshopsdk/photoshop
   # Should show: PIFormat.h, PIGeneral.h, etc.
   ```

2. If not there, check where it actually is:
   ```bash
   find ~/src -name "PIFormat.h" -type f
   # Shows: ~/src/pluginsdk/photoshop/PIFormat.h
   ```

3. Either rename it or use `-DPHOTOSHOP_SDK_PATH`:
   ```bash
   # Rename (recommended)
   mv ~/src/pluginsdk ~/src/photoshopsdk
   
   # Or tell CMake where it is
   cmake -B build -DPHOTOSHOP_SDK_PATH=~/src/pluginsdk
   ```

### Error: No such file 'PIFormat.h'

This means the SDK path is wrong or incomplete.

**Check:**
```bash
# Should show the file
ls ~/src/photoshopsdk/photoshop/PIFormat.h

# If not found, find where PIFormat.h actually is
find ~/src -name "PIFormat.h" -type f
```

**Fix:**
Set the correct path:
```bash
cmake -B build -DPHOTOSHOP_SDK_PATH=/correct/path/to/sdk
```

### SDK Version Compatibility

The HEICFormat plugin is designed for Photoshop SDK version **2019 or later**.

Older SDK versions may work but are not tested. If you have issues:

1. Download the latest SDK from Adobe Console
2. Use SDK version 2021 or later (recommended)

### Multiple SDK Versions

If you have multiple SDK versions:

```
~/src/
├── photoshopsdk-2021/
├── photoshopsdk-2023/
└── HEICFormat/
```

Specify which one to use:
```bash
cmake -B build -DPHOTOSHOP_SDK_PATH=~/src/photoshopsdk-2023
```

## SDK Contents Required

The following SDK directories are required for building:

- ✅ `photoshop/` - Photoshop API headers
- ✅ `pica_sp/` - PICA Suite headers  
- ✅ `common/includes/` - Common headers
- ✅ `common/resources/` - Resource files
- ✅ `common/sources/` - Common source files

If any of these are missing, the SDK extraction may be incomplete. Re-download and extract the SDK.

## Environment Variable (Alternative)

You can also set an environment variable:

```bash
# In your ~/.zshrc or ~/.bashrc
export PHOTOSHOP_SDK_PATH=~/src/photoshopsdk

# Then just build normally
cmake -B build
```

## For Xcode Project Users

If you're using the Xcode project instead of CMake, it expects the SDK at:

```
~/src/
└── photoshopapi/       # Note: different name for Xcode
    └── ...
```

Or update the Xcode project paths to point to your SDK location.

## Quick Setup

```bash
# Download SDK from Adobe Console first!
cd ~/Downloads
unzip adobe_photoshop_sdk_*.zip

# Move to standard location
mkdir -p ~/src
mv adobe_photoshop_sdk_* ~/src/photoshopsdk

# Verify structure
ls ~/src/photoshopsdk/pluginsdk/photoshopapi/photoshop/PIFormat.h
# Should find the file

# Build the plugin
cd ~/src/HEICFormat
./build.sh
./install.sh
```

