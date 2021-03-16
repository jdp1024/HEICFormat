//
// HEIC format write support plug-in for Adobe Photoshop
// Copyright (c) 2021 jdp.
// Distributed under GPLv3 license.
//

#pragma once

#import <Cocoa/Cocoa.h>

#include "HEIC_UI.h"

typedef enum {
	DIALOG_RESULT_OK = 0,
	DIALOG_RESULT_CANCEL = 1,
    DIALOG_RESULT_INVALID = -1
} DialogResult;

@interface HEIC_UI_Controller : NSObject {
    IBOutlet NSWindow *theWindow;
    IBOutlet NSMatrix *alphaMatrix;
	IBOutlet NSSlider *quantizeSlider;
	IBOutlet NSTextField *sliderLabel;
    IBOutlet NSTextField *qualityEdit;
    IBOutlet NSButton *saveExifCheckbox;
    IBOutlet NSButton *saveXmpCheckbox;
	IBOutlet NSButton *revealInFinderCheckbox;
    IBOutlet NSButton *quietCheckbox;
    IBOutlet NSButton *convertToSRGBCheckbox;
	DialogResult theResult;
}
- (id)init;

- (IBAction)clickedOK:(id)sender;
- (IBAction)clickedCancel:(id)sender;
- (DialogResult)getResult;

- (IBAction)trackQuantQuality:(id)sender;
- (IBAction)trackQualityValue:(id)sender;

- (NSWindow *)getWindow;

@end
