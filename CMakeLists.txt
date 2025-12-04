cmake_minimum_required(VERSION 3.15)
project(HEICFormat VERSION 0.1.2 LANGUAGES C CXX OBJC OBJCXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_OSX_DEPLOYMENT_TARGET "10.13" CACHE STRING "Minimum macOS deployment version")

# Detect host architecture automatically
if(NOT CMAKE_OSX_ARCHITECTURES)
    execute_process(
        COMMAND uname -m
        OUTPUT_VARIABLE HOST_ARCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    
    if(HOST_ARCH STREQUAL "arm64")
        set(CMAKE_OSX_ARCHITECTURES "arm64" CACHE STRING "Build architecture")
        message(STATUS "Detected Apple Silicon (arm64) - building for arm64")
    elseif(HOST_ARCH STREQUAL "x86_64")
        set(CMAKE_OSX_ARCHITECTURES "x86_64" CACHE STRING "Build architecture")
        message(STATUS "Detected Intel Mac (x86_64) - building for x86_64")
    else()
        set(CMAKE_OSX_ARCHITECTURES "${HOST_ARCH}" CACHE STRING "Build architecture")
        message(STATUS "Detected architecture: ${HOST_ARCH}")
    endif()
endif()

# Find Adobe Photoshop SDK
set(PHOTOSHOP_SDK_PATH "${CMAKE_SOURCE_DIR}/../photoshopsdk/pluginsdk/photoshopapi" CACHE PATH "Path to Adobe Photoshop SDK")
if(NOT EXISTS "${PHOTOSHOP_SDK_PATH}")
    message(FATAL_ERROR "Adobe Photoshop SDK not found at ${PHOTOSHOP_SDK_PATH}. "
                        "Please download it from https://console.adobe.io/downloads and extract to ${PHOTOSHOP_SDK_PATH}")
endif()

# Find required packages using pkg-config
find_package(PkgConfig REQUIRED)

# Try to find libheif
pkg_check_modules(LIBHEIF REQUIRED libheif)
message(STATUS "Found libheif: ${LIBHEIF_LIBDIR}")

# Try to find x265
pkg_check_modules(X265 REQUIRED x265)
message(STATUS "Found x265: ${X265_LIBDIR}")

# Try to find lcms2
pkg_check_modules(LCMS2 REQUIRED lcms2)
message(STATUS "Found lcms2: ${LCMS2_LIBDIR}")

# Check for fast float plugin (optional optimization)
set(LCMS2_FAST_FLOAT_LIB "")
set(HAVE_LCMS2_FAST_FLOAT FALSE)

# Try to find fast_float plugin in common locations
set(FAST_FLOAT_PATHS
    "${LCMS2_LIBDIR}/liblcms2_fast_float.a"
    "/opt/homebrew/lib/liblcms2_fast_float.a"
    "/usr/local/lib/liblcms2_fast_float.a"
    "$ENV{HOME}/lib/liblcms2_fast_float.a"
)

foreach(path ${FAST_FLOAT_PATHS})
    if(EXISTS "${path}")
        set(LCMS2_FAST_FLOAT_LIB "${path}")
        set(HAVE_LCMS2_FAST_FLOAT TRUE)
        message(STATUS "Found liblcms2_fast_float (optional optimization): ${path}")
        break()
    endif()
endforeach()

if(NOT HAVE_LCMS2_FAST_FLOAT)
    message(STATUS "liblcms2_fast_float not found - using standard lcms2 (plugin will work fine)")
endif()

# Find Cocoa framework
find_library(COCOA_FRAMEWORK Cocoa REQUIRED)

# Adobe Photoshop SDK paths
set(COMMON_SDK_PATH "${PHOTOSHOP_SDK_PATH}/../samplecode/common")
set(PHOTOSHOP_INCLUDES
    "${PHOTOSHOP_SDK_PATH}/photoshop"
    "${PHOTOSHOP_SDK_PATH}/pica_sp"
    "${COMMON_SDK_PATH}/includes"
)

# Source files
set(COMMON_SOURCES
    common/HEICFormat.cpp
    common/HEIC_log.c
)

set(MAC_SOURCES
    mac/HEIC_UI_Cocoa.mm
    mac/HEIC_UI_Controller.m
)

# Adobe SDK source files (need to be compiled)
# Note: .cpp files use Objective-C++ on macOS
set(SDK_SOURCES
    "${COMMON_SDK_PATH}/sources/PIMacUI.cpp"
    "${COMMON_SDK_PATH}/sources/PIUSuites.cpp"
    "${COMMON_SDK_PATH}/sources/DialogUtilitiesMac.cpp"
    "${COMMON_SDK_PATH}/sources/PIUtilities.cpp"
    "${COMMON_SDK_PATH}/sources/PropertyUtils.cpp"
    "${COMMON_SDK_PATH}/sources/FileUtilitiesMac.cpp"
)

# On macOS, all .cpp files that include Cocoa/Foundation must use Objective-C++
set(OBJCXX_SOURCES
    common/HEICFormat.cpp
    ${SDK_SOURCES}
)

# Set these .cpp files to compile as Objective-C++
set_source_files_properties(${OBJCXX_SOURCES}
    PROPERTIES
    COMPILE_FLAGS "-x objective-c++"
)

# Check if SDK sources exist
foreach(src ${SDK_SOURCES})
    if(NOT EXISTS ${src})
        message(WARNING "SDK source not found: ${src}")
    endif()
endforeach()

# Create the plugin bundle
add_library(HEICFormat MODULE
    ${COMMON_SOURCES}
    ${MAC_SOURCES}
    ${SDK_SOURCES}
)

# Set bundle properties
set_target_properties(HEICFormat PROPERTIES
    BUNDLE TRUE
    BUNDLE_EXTENSION "plugin"
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/Info.plist"
    OUTPUT_NAME "HEICFormat"
)

# Include directories
target_include_directories(HEICFormat PRIVATE
    ${CMAKE_SOURCE_DIR}/common
    ${CMAKE_SOURCE_DIR}/mac
    ${PHOTOSHOP_INCLUDES}
    ${LIBHEIF_INCLUDE_DIRS}
    ${X265_INCLUDE_DIRS}
    ${LCMS2_INCLUDE_DIRS}
)

# Compiler flags
target_compile_options(HEICFormat PRIVATE
    -Wall
    $<$<CONFIG:Release>:-O3>
    $<$<CONFIG:Release>:-DNDEBUG>
)

# Add fast_float define if available
if(HAVE_LCMS2_FAST_FLOAT)
    target_compile_definitions(HEICFormat PRIVATE HAVE_LCMS2_FAST_FLOAT)
endif()

# Link libraries statically to avoid runtime dependency issues
# Find static libraries
find_library(LIBHEIF_STATIC NAMES libheif.a PATHS ${LIBHEIF_LIBDIR} NO_DEFAULT_PATH)
find_library(X265_STATIC NAMES libx265.a PATHS ${X265_LIBDIR} NO_DEFAULT_PATH)
# Find static lcms2 (check Homebrew locations too)
find_library(LCMS2_STATIC NAMES liblcms2.a 
    PATHS 
        ${LCMS2_LIBDIR}
        /opt/homebrew/lib
        /usr/local/lib
    NO_DEFAULT_PATH
)

# Find libheif's dependencies
find_library(LIBDE265_STATIC NAMES libde265.a PATHS /opt/homebrew/opt/libde265/lib /usr/local/lib)
find_library(AOM_STATIC NAMES libaom.a PATHS /opt/homebrew/opt/aom/lib /usr/local/lib)
find_library(SHARPYUV_STATIC NAMES libsharpyuv.a PATHS /opt/homebrew/opt/webp/lib /usr/local/lib)
find_library(LIBVMAF_STATIC NAMES libvmaf.a PATHS /opt/homebrew/opt/libvmaf/lib /usr/local/lib)

if(LIBHEIF_STATIC)
    message(STATUS "Using static libheif: ${LIBHEIF_STATIC}")
else()
    message(FATAL_ERROR "Static libheif.a not found. Required for plugin.")
endif()

if(X265_STATIC)
    message(STATUS "Using static x265: ${X265_STATIC}")
else()
    message(FATAL_ERROR "Static libx265.a not found. Required for plugin.")
endif()

if(LCMS2_STATIC)
    message(STATUS "Using static lcms2: ${LCMS2_STATIC}")
else()
    message(FATAL_ERROR "Static liblcms2.a not found. Required for plugin.")
endif()

# Link static libraries (order matters!)
target_link_libraries(HEICFormat PRIVATE
    ${COCOA_FRAMEWORK}
    ${LIBHEIF_STATIC}
    ${X265_STATIC}
    ${LCMS2_STATIC}
    "-framework CoreFoundation"
    "-framework ApplicationServices"
)

# Link fast_float plugin if available (optional optimization)
if(HAVE_LCMS2_FAST_FLOAT AND LCMS2_FAST_FLOAT_LIB)
    target_link_libraries(HEICFormat PRIVATE ${LCMS2_FAST_FLOAT_LIB})
endif()

# Add optional static dependencies if found
if(LIBDE265_STATIC)
    target_link_libraries(HEICFormat PRIVATE ${LIBDE265_STATIC})
    message(STATUS "Linked static libde265: ${LIBDE265_STATIC}")
endif()
if(AOM_STATIC)
    target_link_libraries(HEICFormat PRIVATE ${AOM_STATIC})
    message(STATUS "Linked static aom: ${AOM_STATIC}")
endif()
if(SHARPYUV_STATIC)
    target_link_libraries(HEICFormat PRIVATE ${SHARPYUV_STATIC})
    message(STATUS "Linked static sharpyuv: ${SHARPYUV_STATIC}")
endif()
if(LIBVMAF_STATIC)
    target_link_libraries(HEICFormat PRIVATE ${LIBVMAF_STATIC})
    message(STATUS "Linked static libvmaf: ${LIBVMAF_STATIC}")
endif()

# Ensure we prefer static libs
set_target_properties(HEICFormat PROPERTIES
    LINK_FLAGS "-Wl,-search_paths_first"
)

# Handle resource compilation (Rez)
find_program(REZ_COMMAND Rez)
if(REZ_COMMAND)
    message(STATUS "Found Rez: ${REZ_COMMAND}")
    
    set(REZ_SOURCE "${CMAKE_SOURCE_DIR}/common/HEICFormat.r")
    set(REZ_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/HEICFormat.rsrc")
    
    add_custom_command(
        OUTPUT ${REZ_OUTPUT}
        COMMAND ${REZ_COMMAND}
            -o ${REZ_OUTPUT}
            -useDF
            -p "${COMMON_SDK_PATH}/includes/MachOMacrezXcode.h"
            -i "${PHOTOSHOP_SDK_PATH}/photoshop"
            -i "${PHOTOSHOP_SDK_PATH}/pica_sp"
            -i "${PHOTOSHOP_SDK_PATH}/resources"
            -i "${COMMON_SDK_PATH}/resources"
            -i "${COMMON_SDK_PATH}/includes"
            ${REZ_SOURCE}
        DEPENDS ${REZ_SOURCE}
        COMMENT "Compiling Rez resources"
    )
    
    add_custom_target(RezResources ALL DEPENDS ${REZ_OUTPUT})
    add_dependencies(HEICFormat RezResources)
    
    # Copy Rez resources to bundle
    add_custom_command(TARGET HEICFormat POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy ${REZ_OUTPUT}
                $<TARGET_BUNDLE_DIR:HEICFormat>/Contents/Resources/HEICFormat.rsrc
        COMMENT "Copying Rez resources to bundle"
    )
else()
    message(WARNING "Rez not found. Resource file will not be compiled.")
endif()

# Copy XIB file to bundle
# Compile XIB to NIB using ibtool
add_custom_command(TARGET HEICFormat POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory
            $<TARGET_BUNDLE_DIR:HEICFormat>/Contents/Resources
    COMMAND ibtool --compile
            $<TARGET_BUNDLE_DIR:HEICFormat>/Contents/Resources/HEIC_UI.nib
            ${CMAKE_SOURCE_DIR}/mac/HEIC_UI.xib
    COMMENT "Compiling XIB to NIB"
)

# Handle exports file for symbol visibility
if(EXISTS "${CMAKE_SOURCE_DIR}/mac/HEIC_exports")
    set_target_properties(HEICFormat PROPERTIES
        LINK_FLAGS "-exported_symbols_list ${CMAKE_SOURCE_DIR}/mac/HEIC_exports"
    )
endif()

# Installation - Use shared Adobe plugin directory
set(ADOBE_SHARED_PLUGIN_DIR "/Library/Application Support/Adobe/Plug-Ins/CC/File Formats")

message(STATUS "")
message(STATUS "Plugin will be installed to shared Adobe directory:")
message(STATUS "  ${ADOBE_SHARED_PLUGIN_DIR}")
message(STATUS "This location works for all Adobe Photoshop versions.")
message(STATUS "Run: sudo cmake --install build")
message(STATUS "")

# Install plugin to shared Adobe directory
install(DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/HEICFormat.plugin"
    DESTINATION "${ADOBE_SHARED_PLUGIN_DIR}"
    USE_SOURCE_PERMISSIONS
)

# Post-install: set permissions
install(CODE "
    set(PLUGIN_PATH \"${ADOBE_SHARED_PLUGIN_DIR}/HEICFormat.plugin\")
    
    message(STATUS \"Installing plugin to shared Adobe directory...\")
    
    # Set permissions
    execute_process(
        COMMAND xattr -cr \"\${PLUGIN_PATH}\"
        RESULT_VARIABLE XATTR_RESULT
        OUTPUT_QUIET ERROR_QUIET
    )
    execute_process(
        COMMAND chmod -R a+rX \"\${PLUGIN_PATH}\"
        RESULT_VARIABLE CHMOD_RESULT
        OUTPUT_QUIET ERROR_QUIET
    )
    execute_process(
        COMMAND chmod a+x \"\${PLUGIN_PATH}/Contents/MacOS/HEICFormat\"
        RESULT_VARIABLE CHMOD_RESULT2
        OUTPUT_QUIET ERROR_QUIET
    )
    
    if(XATTR_RESULT EQUAL 0 AND CHMOD_RESULT EQUAL 0 AND CHMOD_RESULT2 EQUAL 0)
        message(STATUS \"✓ Installation successful\")
        message(STATUS \"\")
        message(STATUS \"Plugin installed at:\")
        message(STATUS \"  \${PLUGIN_PATH}\")
        message(STATUS \"\")
        message(STATUS \"This plugin will work with ALL Adobe Photoshop versions.\")
        message(STATUS \"Please restart Photoshop for the plugin to take effect.\")
    else()
        message(WARNING \"⚠ Installed but failed to set some permissions\")
    endif()
    
    message(STATUS \"\")
")

# Print configuration summary
message(STATUS "")
message(STATUS "=== HEICFormat Configuration ===")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Architecture: ${CMAKE_OSX_ARCHITECTURES}")
message(STATUS "Photoshop SDK: ${PHOTOSHOP_SDK_PATH}")
message(STATUS "Install directory: ${PHOTOSHOP_PLUGIN_DIR}")
message(STATUS "libheif: ${LIBHEIF_LIBDIR}")
message(STATUS "x265: ${X265_LIBDIR}")
message(STATUS "lcms2: ${LCMS2_LIBDIR}")
if(HAVE_LCMS2_FAST_FLOAT)
    message(STATUS "lcms2_fast_float: ${LCMS2_FAST_FLOAT_LIB} (optimization enabled)")
else()
    message(STATUS "lcms2_fast_float: NOT FOUND (using standard lcms2 - plugin works fine)")
endif()
message(STATUS "================================")
message(STATUS "")

