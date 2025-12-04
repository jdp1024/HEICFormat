//
// HEIC format write support plug-in for Adobe Photoshop
// Copyright (c) 2021 jdp.
// Distributed under GPLv3 license.
//

#pragma once

#import <CoreFoundation/CoreFoundation.h>

// Plugin options structure (C/Objective-C compatible)
typedef struct HEICParam {
    int quality;
    BOOL saveExif;
    BOOL saveXmp;
    BOOL revealInFinder;
    BOOL quiet;
    BOOL convertToSRGB;
    // Per-export options (not saved in preferences)
    BOOL saveTransparency;   // Set at export time based on user choice
    BOOL hasAlpha;           // Whether document has transparency available
} HEICParam;

#ifdef __cplusplus
extern "C" {
#endif

void loadOptions(HEICParam* opt);
void saveOptions(const HEICParam* opt);
bool HEIC_UI(const void *userdata, HEICParam* opt);

#ifdef __cplusplus
}
#endif
