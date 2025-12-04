//
// HEIC format write support plug-in for Adobe Photoshop
// Copyright (c) 2021 jdp.
// Distributed under GPLv3 license.
//

#pragma once

#import <Cocoa/Cocoa.h>

#include "HEIC_UI.h"

// Modern Objective-C enum declaration
typedef NS_ENUM(NSInteger, DialogResult) {
	DIALOG_RESULT_OK = 0,
	DIALOG_RESULT_CANCEL = 1,
    DIALOG_RESULT_INVALID = -1
};

@interface HEIC_UI_Controller : NSObject {
    // UI outlets - in MRC these are weak references, actual retention is via topLevelObjects
    IBOutlet NSWindow *theWindow;
	IBOutlet NSSlider *quantizeSlider;
	IBOutlet NSTextField *sliderLabel;
    IBOutlet NSTextField *qualityEdit;
    IBOutlet NSButton *saveTransparencyCheckbox;
    IBOutlet NSButton *saveExifCheckbox;
    IBOutlet NSButton *saveXmpCheckbox;
	IBOutlet NSButton *revealInFinderCheckbox;
    IBOutlet NSButton *quietCheckbox;
    IBOutlet NSButton *convertToSRGBCheckbox;

    // State
	DialogResult theResult;

    // Options to modify
    HEICParam* options;
    // Flag to track if we own the options memory (for cleanup)
    BOOL ownsOptions;

    // Top-level NIB objects - retained to keep all UI elements alive
    NSArray *topLevelObjects;
}

- (id)initWithOptions:(HEICParam*)opt;
- (id)init;
- (void)dealloc;

- (IBAction)clickedOK:(id)sender;
- (IBAction)clickedCancel:(id)sender;
- (DialogResult)getResult;

- (IBAction)trackQuantQuality:(id)sender;
- (IBAction)trackQualityValue:(id)sender;

- (NSWindow *)getWindow;
- (void)setHasAlpha:(BOOL)hasAlpha;

@end
