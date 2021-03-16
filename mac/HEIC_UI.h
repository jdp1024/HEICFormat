//
// HEIC format write support plug-in for Adobe Photoshop
// Copyright (c) 2021 jdp.
// Distributed under GPLv3 license.
//

#pragma once

#import <CoreFoundation/CoreFoundation.h>

typedef struct {
    int quality;
    int alpha;
    BOOL saveExif;
    BOOL saveXmp;
    BOOL revealInFinder;
    BOOL quiet;
    BOOL convertToSRGB;
} HEICParam;

#ifdef __cplusplus
extern "C" {
#endif

void loadOptions(HEICParam* opt);
void saveOptions(const HEICParam* opt);
bool HEIC_UI(const void *userdata);

#ifdef __cplusplus
}
#endif
