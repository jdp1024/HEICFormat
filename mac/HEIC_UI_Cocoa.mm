//
// HEIC format write support plug-in for Adobe Photoshop
// Copyright (c) 2021 jdp.
// Distributed under GPLv3 license.
//

#include "HEIC_UI.h"
#include "HEIC_log.h"
#import "HEIC_UI_Controller.h"

bool HEIC_UI(const void *userdata) {
	bool result = false;
	Class controllerClass = [[NSBundle bundleWithIdentifier:@"com.jdp.heic"] classNamed:@"HEIC_UI_Controller"];
    if (!controllerClass) return false;

    HEIC_UI_Controller *controller = [[controllerClass alloc] init];
    if (!controller) return false;

    NSWindow *window = [controller getWindow];
    if (window) {
        NSInteger modal = NSRunContinuesResponse;
        DialogResult res = DIALOG_RESULT_INVALID;
        NSModalSession modal_session = [NSApp beginModalSessionForWindow:window];
        do {
            modal = [NSApp runModalSession:modal_session];
            res = [controller getResult];
        } while (res == DIALOG_RESULT_INVALID && modal == NSRunContinuesResponse);
        [NSApp endModalSession:modal_session];

        result = (res == DIALOG_RESULT_OK || modal == NSRunStoppedResponse);
        [window close];
    }
    [controller release];
	return result;
}
