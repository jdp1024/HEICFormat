//
// HEIC format write support plug-in for Adobe Photoshop
// Copyright (c) 2021 jdp.
// Distributed under GPLv3 license.
//

#import "HEIC_UI_Controller.h"

#include "HEIC_log.h"

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
        kKeyHEICQuality : @55,
        kKeyHEICSaveExif : @YES,
        kKeyHEICSaveXmp : @YES,
        kKeyHEICRevealInFinder : @NO,
        kKeyHEICQuiet : @NO,
        kKeyHEICConvertToSRGB : @NO,
    }];

    opt->quality = [def integerForKey:kKeyHEICQuality];
    opt->saveExif = [def boolForKey:kKeyHEICSaveExif];
    opt->saveXmp = [def boolForKey:kKeyHEICSaveXmp];
    opt->revealInFinder = [def boolForKey:kKeyHEICRevealInFinder];
    opt->quiet = [def boolForKey:kKeyHEICQuiet];
    opt->convertToSRGB = [def boolForKey:kKeyHEICConvertToSRGB];
    
    // Per-export options (not saved in preferences)
    opt->saveTransparency = YES;  // Default to YES
    opt->hasAlpha = NO;           // Will be set by the caller

    if (opt->quality < 1 || opt->quality > 100) opt->quality = 50;
    
    [def release];
}

void saveOptions(const HEICParam* opt) {
    NSUserDefaults* def = [[NSUserDefaults alloc] initWithSuiteName:kVendorDomain];
    [def setInteger:opt->quality forKey:kKeyHEICQuality];
    [def setBool:opt->saveExif forKey:kKeyHEICSaveExif];
    [def setBool:opt->saveXmp forKey:kKeyHEICSaveXmp];
    [def setBool:opt->revealInFinder forKey:kKeyHEICRevealInFinder];
    [def setBool:opt->quiet forKey:kKeyHEICQuiet];
    [def setBool:opt->convertToSRGB forKey:kKeyHEICConvertToSRGB];
    // Note: saveTransparency is NOT saved - it's a per-export decision
    [def release];
}

@implementation HEIC_UI_Controller

- (id)initWithOptions:(HEICParam*)opt {
	self = [super init];
    if (!self) {
        return nil;
    }

    options = opt;  // Store reference to options to modify
    ownsOptions = NO;  // By default, we don't own the memory

    // Get the plugin bundle
    NSBundle *pluginBundle = [NSBundle bundleForClass:[self class]];
    if (!pluginBundle) {
        xlog("HEIC_UI_Controller: ERROR - Could not get plugin bundle\n");
        [self release];
        return nil;
    }

    // Load the NIB file
    // In MRC, loadNibNamed returns an autoreleased array, and the objects in it are also autoreleased
    // We MUST retain the array to keep all objects alive
    NSArray *nibObjects = nil;
    if (![pluginBundle loadNibNamed:@"HEIC_UI" owner:self topLevelObjects:&nibObjects]) {
        xlog("HEIC_UI_Controller: ERROR - Failed to load NIB\n");
        [self release];
        return nil;
    }

    // Retain the top-level objects - this keeps everything alive
    topLevelObjects = [nibObjects retain];

    if (!theWindow) {
        xlog("HEIC_UI_Controller: ERROR - Window outlet not connected\n");
        [topLevelObjects release];
        topLevelObjects = nil;
        [self release];
        return nil;
    }

    // Load saved options for persistent settings, but use passed options for per-export settings
    HEICParam savedOpt;
    loadOptions(&savedOpt);

    // Set UI values - use saved options for persistent settings, passed options for per-export
    [qualityEdit setIntegerValue:savedOpt.quality];
    [quantizeSlider setIntegerValue:savedOpt.quality];
    [saveTransparencyCheckbox setState:opt->saveTransparency ? NSControlStateValueOn : NSControlStateValueOff];
    [saveExifCheckbox setState:savedOpt.saveExif ? NSControlStateValueOn : NSControlStateValueOff];
    [saveXmpCheckbox setState:savedOpt.saveXmp ? NSControlStateValueOn : NSControlStateValueOff];
    [revealInFinderCheckbox setState:savedOpt.revealInFinder ? NSControlStateValueOn : NSControlStateValueOff];
    [quietCheckbox setState:savedOpt.quiet ? NSControlStateValueOn : NSControlStateValueOff];
    [convertToSRGBCheckbox setState:savedOpt.convertToSRGB ? NSControlStateValueOn : NSControlStateValueOff];

    [self trackQuantQuality:self];
	[theWindow center];
    theResult = DIALOG_RESULT_INVALID;

	return self;
}

- (id)init {
    // For backward compatibility, create heap-allocated default options
    HEICParam* optPtr = (HEICParam*)malloc(sizeof(HEICParam));
    if (!optPtr) {
        [self release];
        return nil;
    }
    loadOptions(optPtr);

    // Initialize with heap-allocated options
    self = [self initWithOptions:optPtr];
    if (self) {
        ownsOptions = YES;  // We own this memory, so we need to free it
    } else {
        free(optPtr);
    }

    return self;
}

- (void)dealloc {
    // Release the top-level objects array
    [topLevelObjects release];
    topLevelObjects = nil;

    // Free options memory if we own it
    if (ownsOptions && options) {
        free(options);
        options = NULL;
    }

    [super dealloc];
}

- (IBAction)clickedOK:(id)sender {
    if (options) {
        // Update the passed-in options
        options->quality = [qualityEdit integerValue];
        options->saveTransparency = [saveTransparencyCheckbox state] == NSControlStateValueOn;
        options->saveExif = [saveExifCheckbox state] == NSControlStateValueOn;
        options->saveXmp = [saveXmpCheckbox state] == NSControlStateValueOn;
        options->revealInFinder = [revealInFinderCheckbox state] == NSControlStateValueOn;
        options->quiet = [quietCheckbox state] == NSControlStateValueOn;
        options->convertToSRGB = [convertToSRGBCheckbox state] == NSControlStateValueOn;
    }

    // Save persistent options (excluding per-export options)
    HEICParam persistentOpt;
    persistentOpt.quality = [qualityEdit integerValue];
    persistentOpt.saveExif = [saveExifCheckbox state] == NSControlStateValueOn;
    persistentOpt.saveXmp = [saveXmpCheckbox state] == NSControlStateValueOn;
    persistentOpt.revealInFinder = [revealInFinderCheckbox state] == NSControlStateValueOn;
    persistentOpt.quiet = [quietCheckbox state] == NSControlStateValueOn;
    persistentOpt.convertToSRGB = [convertToSRGBCheckbox state] == NSControlStateValueOn;
    // Don't save saveTransparency - it's per-export

    saveOptions(&persistentOpt);

	theResult = DIALOG_RESULT_OK;
    [NSApp stopModal];
}

- (IBAction)clickedCancel:(id)sender {
    theResult = DIALOG_RESULT_CANCEL;
    [NSApp stopModal];
}

- (DialogResult)getResult {
	return theResult;
}

- (IBAction)trackQuantQuality:(id)sender {
	NSInteger quality = [quantizeSlider integerValue];
    NSString* quality_string = [NSString stringWithFormat:@"Quality: %ld", (long)quality];
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

- (void)setHasAlpha:(BOOL)hasAlpha {
    // Hide and disable the transparency checkbox if no alpha is available
    if (!hasAlpha) {
        [saveTransparencyCheckbox setEnabled:NO];
        [saveTransparencyCheckbox setState:NSControlStateValueOff];
        [saveTransparencyCheckbox setHidden:YES];
    } else {
        [saveTransparencyCheckbox setEnabled:YES];
        [saveTransparencyCheckbox setHidden:NO];
    }
}

@end
