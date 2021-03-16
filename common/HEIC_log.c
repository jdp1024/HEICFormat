//
// HEIC format write support plug-in for Adobe Photoshop
// Copyright (c) 2021 jdp.
// Distributed under GPLv3 license.
//

#include "HEIC_log.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

static void log_format(const char* message, va_list args) {
    FILE *fp = fopen("/tmp/heic.log", "wb");
    if (fp) {
        vfprintf(fp, message, args);
        fflush(fp);
        fclose(fp);
    }
}

void xlog(const char* message, ...) {
    va_list args;
    va_start(args, message);
    log_format(message, args);
    va_end(args);
}

