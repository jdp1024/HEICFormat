//
// HEIC format write support plug-in for Adobe Photoshop
// Copyright (c) 2021 jdp.
// Distributed under GPLv3 license.
//

#include "HEIC_UI.h"
#include "HEIC_log.h"
#import "HEIC_UI_Controller.h"
#include "PIFormat.h"

bool HEIC_UI(const void *userdata, HEICParam* opt) {
    // Create an autorelease pool for all autoreleased objects
    // This is critical in MRC - NIB loading creates many autoreleased objects
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    bool result = false;
    bool shouldExitEarly = false;
    HEIC_UI_Controller *controller = nil;
    NSWindow *window = nil;
    HEICParam* defaultOptPtr = NULL;  // For heap-allocated default options

    @try {
        // Get the controller class from the bundle
        Class controllerClass = [[NSBundle bundleWithIdentifier:@"com.jdp.heic"] classNamed:@"HEIC_UI_Controller"];
        if (!controllerClass) {
            xlog("HEIC_UI: ERROR - Could not find HEIC_UI_Controller class\n");
            shouldExitEarly = true;
        }

        if (!shouldExitEarly) {
            // Allocate and initialize the controller (loads NIB and sets up UI)
            // For about dialog (opt == NULL), use heap-allocated default options
            if (!opt) {
                defaultOptPtr = (HEICParam*)malloc(sizeof(HEICParam));
                if (defaultOptPtr) {
                    loadOptions(defaultOptPtr);
                    opt = defaultOptPtr;
                } else {
                    xlog("HEIC_UI: ERROR - Could not allocate default options\n");
                    shouldExitEarly = true;
                }
            }

            if (!shouldExitEarly) {
                controller = [[controllerClass alloc] initWithOptions:opt];
                if (!controller) {
                    xlog("HEIC_UI: ERROR - Could not initialize controller\n");
                    shouldExitEarly = true;
                }
            }
        }

        if (!shouldExitEarly) {
            // Check if document has alpha channels
            // userdata is a FormatRecordPtr (or NULL for About dialog)
            BOOL hasAlpha = YES;  // Default to YES for About dialog
            if (userdata != NULL) {
                FormatRecordPtr formatRecord = (FormatRecordPtr)userdata;
                // planes >= 4 means RGBA data is available
                hasAlpha = (formatRecord->planes >= 4);
            }

            // Tell the controller whether alpha is available
            [controller setHasAlpha:hasAlpha];

            // Get the window
            window = [controller getWindow];
            if (!window) {
                xlog("HEIC_UI: ERROR - Could not get window from controller\n");
                shouldExitEarly = true;
            }
        }

        if (!shouldExitEarly) {
            // Show the window and run modally
            [window makeKeyAndOrderFront:nil];

            // Run the modal session
            NSModalSession session = [NSApp beginModalSessionForWindow:window];

            DialogResult dialogResult = DIALOG_RESULT_INVALID;
            NSInteger modalResult = NSModalResponseContinue;

            while (dialogResult == DIALOG_RESULT_INVALID && modalResult == NSModalResponseContinue) {
                modalResult = [NSApp runModalSession:session];
                dialogResult = [controller getResult];
            }

            [NSApp endModalSession:session];

            // Determine result
            result = (dialogResult == DIALOG_RESULT_OK);

            // Close and order out the window before releasing the controller
            [window orderOut:nil];
        }
    }
    @catch (NSException *exception) {
        xlog("HEIC_UI: EXCEPTION - %s: %s\n",
             [[exception name] UTF8String],
             [[exception reason] UTF8String]);
        result = false;
        shouldExitEarly = true;
    }
    @finally {
        // Release the controller - this will release topLevelObjects and deallocate everything
        if (controller) {
            [controller release];
            controller = nil;
        }

        // Free heap-allocated default options if any
        if (defaultOptPtr) {
            free(defaultOptPtr);
            defaultOptPtr = NULL;
        }

        // Drain the autorelease pool
        [pool drain];
    }

	return result;
}
