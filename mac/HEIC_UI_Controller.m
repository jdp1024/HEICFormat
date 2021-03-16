//
// HEIC format write support plug-in for Adobe Photoshop
// Copyright (c) 2021 jdp.
// Distributed under GPLv3 license.
//

#import "HEIC_UI_Controller.h"

#include "HEIC_log.h"

NSString* kKeyHEICAlpha = @"HEIC_Alpha";
NSString* kKeyHEICQuality = @"HEIC_Quality";
NSString* kKeyHEICSaveExif = @"HEIC_SaveExif";
NSString* kKeyHEICSaveXmp = @"HEIC_SaveXmp";
NSString* kKeyHEICRevealInFinder = @"HEIC_RevealInFinder";
NSString* kKeyHEICQuiet = @"HEIC_Quiet";
NSString* kKeyHEICConvertToSRGB = @"HEIC_ConvertToSRGB";
NSString* kVendorDomain = @"com.jdp.heic";

void loadOptions(HEICParam* opt) {
    NSUserDefaults* def = [[NSUserDefaults alloc] initWithSuiteName:kVendorDomain];
    [def registerDefaults:@{
        kKeyHEICAlpha : @0,
        kKeyHEICQuality : @55,
        kKeyHEICSaveExif : @YES,
        kKeyHEICSaveXmp : @YES,
        kKeyHEICRevealInFinder : @NO,
        kKeyHEICQuiet : @NO,
        kKeyHEICConvertToSRGB : @NO,
    }];

    opt->alpha = [def integerForKey:kKeyHEICAlpha];
    opt->quality = [def integerForKey:kKeyHEICQuality];
    opt->saveExif = [def boolForKey:kKeyHEICSaveExif];
    opt->saveXmp = [def boolForKey:kKeyHEICSaveXmp];
    opt->revealInFinder = [def boolForKey:kKeyHEICRevealInFinder];
    opt->quiet = [def boolForKey:kKeyHEICQuiet];
    opt->convertToSRGB = [def boolForKey:kKeyHEICConvertToSRGB];

    if (opt->quality < 1 || opt->quality > 100) opt->quality = 50;
    if (opt->alpha < 0 || opt->alpha > 1) opt->alpha = 0;
}

void saveOptions(const HEICParam* opt) {
    NSUserDefaults* def = [[NSUserDefaults alloc] initWithSuiteName:kVendorDomain];
    [def setInteger:opt->alpha forKey:kKeyHEICAlpha];
    [def setInteger:opt->quality forKey:kKeyHEICQuality];
    [def setBool:opt->saveExif forKey:kKeyHEICSaveExif];
    [def setBool:opt->saveXmp forKey:kKeyHEICSaveXmp];
    [def setBool:opt->revealInFinder forKey:kKeyHEICRevealInFinder];
    [def setBool:opt->quiet forKey:kKeyHEICQuiet];
    [def setBool:opt->convertToSRGB forKey:kKeyHEICConvertToSRGB];
}

@implementation HEIC_UI_Controller

- (id)init {
	self = [super init];

	if (!([NSBundle loadNibNamed:@"HEIC_UI" owner:self])) return nil;

    HEICParam opt;
    loadOptions(&opt);

    [alphaMatrix selectCellAtRow:opt.alpha column:0];
    [qualityEdit setIntegerValue:opt.quality];
    [quantizeSlider setIntegerValue:opt.quality];
    [saveExifCheckbox setState:opt.saveExif ? NSOnState : NSOffState];
    [saveXmpCheckbox setState:opt.saveXmp ? NSOnState : NSOffState];
    [revealInFinderCheckbox setState:opt.revealInFinder ? NSOnState : NSOffState];
    [quietCheckbox setState:opt.quiet ? NSOnState : NSOffState];
    [convertToSRGBCheckbox setState:opt.convertToSRGB ? NSOnState : NSOffState];

    [self trackQuantQuality:self];
	[theWindow center];
    theResult = DIALOG_RESULT_INVALID;
	return self;
}

- (IBAction)clickedOK:(id)sender {
    HEICParam opt;
    opt.alpha = [alphaMatrix selectedRow];
    opt.quality = [qualityEdit integerValue];
    opt.saveExif = [saveExifCheckbox state] == NSOnState;
    opt.saveXmp = [saveXmpCheckbox state] == NSOnState;
    opt.revealInFinder = [revealInFinderCheckbox state] == NSOnState;
    opt.quiet = [quietCheckbox state] == NSOnState;
    opt.convertToSRGB = [convertToSRGBCheckbox state] == NSOnState;

    saveOptions(&opt);
	theResult = DIALOG_RESULT_OK;
}

- (IBAction)clickedCancel:(id)sender {
    theResult = DIALOG_RESULT_CANCEL;
}

- (DialogResult)getResult {
	return theResult;
}

- (IBAction)trackQuantQuality:(id)sender {
	const NSInteger quality = [quantizeSlider integerValue];

	NSString *quality_string = (quality == 100 ? @"Highest Quality" :
								quality > 75 ? @"High Quality" :
                                quality > 50 ? @"Medium Quality" :
								quality > 25 ? @"Low Quality" :
								@"Lowest Quality"
								);
										
	[sliderLabel setStringValue:quality_string];
    [qualityEdit setIntegerValue:quality];
}

- (IBAction)trackQualityValue:(id)sender {
    NSInteger q = [qualityEdit integerValue];
    if (q < 0 || q > 100) {
        [qualityEdit setIntegerValue:55];
        q = 55;
    }

    [quantizeSlider setIntegerValue:q];
    [self trackQuantQuality:sender];
}

- (NSWindow *)getWindow {
	return theWindow;
}

@end
