//
// HEIC format write support plug-in for Adobe Photoshop
// Copyright (c) 2021 jdp.
// Distributed under GPLv3 license.
//

#include "PIDefines.h"
#include "PIFormat.h"
#include "PIUtilities.h"
#include "FileUtilities.h"
#include "PIUI.h"
#include "PropertyUtils.h"
#include "PIProperties.h"
#include "PIUSuites.h"

#import "HEIC_UI.h"
#include "HEIC_log.h"

#include <libheif/heif.h>
#include <lcms2.h>
#ifdef HAVE_LCMS2_FAST_FLOAT
#include <lcms2_fast_float.h>
#endif

#import <CoreFoundation/CoreFoundation.h>

SPBasicSuite* sSPBasic = nullptr;
SPPluginRef gPlugInRef = nullptr;

FormatRecord* gFormatRecord = nullptr;
intptr_t* gDataHandle = nullptr;
int16* gResult = nullptr;
static int gcmsPluginAdded = 0;

static char gSavedPath[256] = { 0 };

#define PF_HALF_CHAN16            16384

static inline unsigned16 RGB16ToRGB8(unsigned16 val) {
    return (val > PF_HALF_CHAN16 ? ( (val - 1) << 1 ) + 1 : val << 1);
}

static inline unsigned16 ByteSwap(unsigned16 val) {
    return ((val >> 8) | (val << 8));
}

inline const char* pastr(Str255 x) {
    return (const char*) &x[1];
}

__attribute__((visibility("default")))
DLLExport MACPASCAL void PluginMain (const int16 selector, FormatRecordPtr formatParamBlock, intptr_t * data, int16 * result);

void DoOptionsStart(FormatRecordPtr formatRecord);
void DoWriteStart(FormatRecordPtr formatRecord);
void DoWriteContinue(FormatRecordPtr formatRecord);
void DoWriteFinish(FormatRecordPtr formatRecord);
void DoWritePrepare(FormatRecordPtr formatRecord);

DLLExport MACPASCAL void PluginMain (const int16 selector, FormatRecordPtr formatParamBlock, intptr_t * data, int16 * result) {
    if (!gcmsPluginAdded) {
#ifdef HAVE_LCMS2_FAST_FLOAT
        cmsPlugin(cmsFastFloatExtensions());
#endif
        gcmsPluginAdded = 1;
    }

    gDataHandle = data;
    gResult = result;
    gFormatRecord = formatParamBlock;

	try { 
        if (selector == formatSelectorAbout) {
            HEIC_UI(NULL, NULL);
        } else {
            sSPBasic = formatParamBlock->sSPBasic;
            gPlugInRef = (SPPluginRef)formatParamBlock->plugInRef;

            if (gFormatRecord->HostSupports32BitCoordinates) {
                gFormatRecord->PluginUsing32BitCoordinates = true;
                gFormatRecord->pluginUsingPOSIXIO = gFormatRecord->hostSupportsPOSIXIO;
            }

            switch (selector) {
                case formatSelectorOptionsStart:
                    DoOptionsStart(formatParamBlock);
                    break;
                case formatSelectorWritePrepare:
                    DoWritePrepare(formatParamBlock);
                    break;
                case formatSelectorWriteStart:
                    DoWriteStart(formatParamBlock);
                    break;
                case formatSelectorWriteContinue:
                    DoWriteContinue(formatParamBlock);
                    break;
                case formatSelectorWriteFinish:
                    DoWriteFinish(formatParamBlock);
                    break;
            }
        }

        if (selector == formatSelectorAbout ||
            selector == formatSelectorWriteFinish ||
            selector == formatSelectorReadFinish ||
            selector == formatSelectorOptionsFinish ||
            selector == formatSelectorEstimateFinish ||
            selector == formatSelectorFilterFile) {
            PIUSuitesRelease();
        }

        *result = noErr;

    } catch (...) {
		if (nullptr != result) {
			*result = -1;
		}
	}

}

// Specialized function for HEICParam struct
void DataToHandle(const HEICParam& data, Handle & h) {
    h = nullptr;
    size_t s = sizeof(HEICParam);
    h = sPSHandle->New((int32) s);
    if (h != nullptr) {
        Boolean oldLock = FALSE;
        Ptr p = nullptr;
        sPSHandle->SetLock(h, true, &p, &oldLock);
        if (p != nullptr) {
            memcpy(p, &data, sizeof(HEICParam));
            sPSHandle->SetLock(h, false, &p, &oldLock);
        } else {
            sPSHandle->Dispose(h);
            h = nullptr;
        }
    }
}

template <class T>
void DataToHandle(const T& data, Handle & h) {
    h = nullptr;
    size_t s = data.size();
    if (s) {
        h = sPSHandle->New((int32) s);
        if (h != nullptr) {
            Boolean oldLock = FALSE;
            Ptr p = nullptr;
            sPSHandle->SetLock(h, true, &p, &oldLock);
            if (p != nullptr) {
                memcpy(p, data.data(), data.size());
                sPSHandle->SetLock(h, false, &p, &oldLock);
            } else {
                sPSHandle->Dispose(h);
                h = nullptr;
            }
        }
    }
}

bool HandleToStruct(Handle h, HEICParam& data) {
    if (h != nullptr) {
        Boolean oldLock = FALSE;
        Ptr p = nullptr;
        sPSHandle->SetLock(h, true, &p, &oldLock);
        if (p != nullptr) {
            memcpy(&data, p, sizeof(HEICParam));
            sPSHandle->SetLock(h, false, &p, &oldLock);
            return true;  // Success
        }
    }
    return false;  // Failed to read from handle
}

static void myAllocateBuffer(FormatRecordPtr formatRecord, const int32 inSize, BufferID *outBufferID) {
    *outBufferID = 0;
    formatRecord->bufferProcs->allocateProc(inSize, outBufferID);
}

static Ptr myLockBuffer(FormatRecordPtr formatRecord, const BufferID inBufferID, Boolean inMoveHigh) {
    return formatRecord->bufferProcs->lockProc(inBufferID, inMoveHigh);
}

static void myUnlockBuffer(FormatRecordPtr formatRecord, const BufferID inBufferID) {
    formatRecord->bufferProcs->unlockProc(inBufferID);
}

static void myFreeBuffer(FormatRecordPtr formatRecord, const BufferID inBufferID) {
    formatRecord->bufferProcs->freeProc(inBufferID);
}

void DoOptionsStart(FormatRecordPtr formatRecord) {
    HEICParam opt;
    loadOptions(&opt);
    if (!opt.quiet) {
        if (HEIC_UI(formatRecord, &opt)) {
            // Store the options in pluginData for use during write
            DataToHandle(opt, formatRecord->revertInfo);
        }
    } else {
        // In quiet mode, store default options
        DataToHandle(opt, formatRecord->revertInfo);
    }
}

void DoWritePrepare(FormatRecordPtr formatRecord) {
    formatRecord->maxData = 0;
}

static void WriteSome(size_t count, const void* const buffer, FormatRecordPtr format_record, int16* const result) {
    //xlog("writesome=%d %d %d\n", (int32)format_record->dataFork, format_record->posixFileDescriptor, format_record->pluginUsingPOSIXIO);

    int32 write_count = (int32)count;
    *result = PSSDKWrite((int32)format_record->dataFork, format_record->posixFileDescriptor, format_record->pluginUsingPOSIXIO, &write_count, (void*)buffer);
    if (*result == noErr && (size_t)write_count != count) *result = dskFulErr;
}

static inline int jdp_hex_to_int(char a) {
    if (a >= '0' && a <= '9') return a - '0';
    if (a >= 'a' && a <= 'f') return 10 + (a - 'a');
    if (a >= 'A' && a <= 'F') return 10 + (a - 'A');
    return -1;
}

static void jdp_urldecode(char* des, const char* src) {
    for (;;) {
        char c = *src++;
        if (!c) break;

        // not a %, just copy over
        if (c != '%') {
            *des++ = c;
            continue;
        }

        // incomplete sequence: %{null}
        char a = *src++;
        if (!a) {
            *des++ = c;
            break;
        }
        // incomplete sequence: %A{null}
        char b = *src++;
        if (!b) {
            *des++ = c;
            *des++ = a;
            break;
        }

        int xhi = jdp_hex_to_int(a);
        int xlo = jdp_hex_to_int(b);

        // invalid sequence: %xy
        if (xhi == -1 || xlo == -1) {
            *des++ = c;
            *des++ = a;
            *des++ = b;
            continue;
        }

        // decode and store
        *des++ = (char)(xhi << 4 | xlo);
    }
    *des = '\0';
}

static heif_error jdp_heif_write(struct heif_context* ctx, const void* data, size_t size, void* userdata) {
    heif_error err;
    err.code = heif_error_Ok;
    err.subcode = heif_suberror_Unspecified;
    err.message = nullptr;

    FormatRecordPtr formatRecord = (FormatRecordPtr) userdata;

    // Modern approach: suppress deprecation warning for FSRef (Photoshop SDK still uses it)
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &formatRecord->fileSpec2->mReference);
    #pragma clang diagnostic pop
    
    // Use modern CFURLCopyFileSystemPath instead of CFURLCopyPath
    CFStringRef pathString = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
    char path[255], rn[256];
    CFStringGetCString(pathString, path, sizeof(path), kCFStringEncodingUTF8);
    CFRelease(pathString);
    CFRelease(url);
    
    jdp_urldecode(rn, path);
    strcpy(gSavedPath, rn);

    if (formatRecord->hostSupportsPluginOpeningFile) {
        FILE* fp = fopen(rn, "wb");
        if (fp) {
            fwrite(data, 1, size, fp);
            fclose(fp);
        }
        *gResult = noErr;
    } else {
        PSSDKSetFPos((int32)formatRecord->dataFork, formatRecord->posixFileDescriptor, formatRecord->pluginUsingPOSIXIO, fsFromStart, 0);
        WriteSome(size, data, gFormatRecord, gResult);
    }
    return err;
}

void DoWriteStart(FormatRecordPtr formatRecord) {
    if (formatRecord->HostSupports32BitCoordinates && formatRecord->imageSize32.h && formatRecord->imageSize32.v)
        formatRecord->PluginUsing32BitCoordinates = TRUE;

    HEICParam opt;
    if (formatRecord->revertInfo && HandleToStruct(formatRecord->revertInfo, opt)) {
        // Successfully loaded options from revertInfo (set in DoOptionsStart)
    } else {
        // Fallback to loading from preferences (handle doesn't exist or can't be read)
        loadOptions(&opt);
    }

    void* clr_profile_data = nullptr;
    int32 clr_profile_size = formatRecord->documentInfo->iCCprofileSize;
    if (formatRecord->documentInfo->iCCprofileData) {
        clr_profile_data = (void*) malloc(clr_profile_size);
        memcpy(clr_profile_data, formatRecord->documentInfo->iCCprofileData, clr_profile_size);
    }

    int width = (formatRecord->PluginUsing32BitCoordinates ? formatRecord->imageSize32.h : formatRecord->imageSize.h);
    int height = (formatRecord->PluginUsing32BitCoordinates ? formatRecord->imageSize32.v : formatRecord->imageSize.v);

    // Check if Photoshop is providing alpha channels
    // planes >= 4 means Photoshop has RGBA data available
    const bool photoshop_has_alpha = (formatRecord->planes >= 4);

    // Save alpha only if:
    // 1. User chose to save transparency (per-export option)
    // 2. AND Photoshop is providing alpha data (planes >= 4)
    const bool save_alpha = opt.saveTransparency && photoshop_has_alpha;

    // Set transparency matting: when not saving transparency, composite against white background
    formatRecord->transparencyMatting = save_alpha ? 0 : 3;  // 3 = white matte

    int hi_plane, num_channels, bit_depth, plane_bytes;
    int col_bytes;

    hi_plane = (save_alpha ? 3 : 2);
    num_channels = (save_alpha ? 4 : 3);
    col_bytes = num_channels;

    if (formatRecord->depth == 16) {
        bit_depth = 16;
        plane_bytes = 2;
        col_bytes *= 2;
    } else if(formatRecord->depth == 1) {
        bit_depth = 1;
        plane_bytes = 1;
    } else {
        bit_depth = 8;
        plane_bytes = 1;
    }

    formatRecord->loPlane = 0;
    formatRecord->hiPlane = hi_plane;
    formatRecord->colBytes = col_bytes;
    formatRecord->rowBytes = col_bytes * width;
    formatRecord->planeBytes = plane_bytes;

    formatRecord->theRect.left = formatRecord->theRect32.left = 0;
    formatRecord->theRect.right = formatRecord->theRect32.right = width;


    const int num_scanlines = height;
    BufferID bufferID = 0;
    int32 framesize = formatRecord->rowBytes * num_scanlines;// * formatRecord->planeBytes;
    myAllocateBuffer(formatRecord, framesize, &bufferID);
    formatRecord->data = myLockBuffer(formatRecord, bufferID, TRUE);

    //xlog("browserRotation=%d hostSupportsPluginOpeningFile=%d\n", formatRecord->browserRotation, formatRecord->hostSupportsPluginOpeningFile);
    //xlog("width=%d height=%d trans=%d alpha=%d bit_depth=%d\n", width, height, have_transparency, have_alpha_channel, bit_depth);
    //xlog("buffersize=%d\n", framesize);

    heif_error err;
    heif_context* ctx = heif_context_alloc();

    heif_encoder* encoder;
    heif_context_get_encoder_for_format(ctx, heif_compression_HEVC, &encoder);
    heif_encoder_set_lossy_quality(encoder, opt.quality);

    heif_image* image;
    err = heif_image_create(width, height, heif_colorspace_RGB, save_alpha ? heif_chroma_interleaved_RGBA : heif_chroma_interleaved_RGB, &image);
    err = heif_image_add_plane(image, heif_channel_interleaved, width, height, 8);

    if (!opt.convertToSRGB && formatRecord->canUseICCProfiles && formatRecord->iCCprofileData && formatRecord->iCCprofileSize > 0) {
        heif_image_set_raw_color_profile(image, "prof", clr_profile_data, clr_profile_size);
    }

    int stride;
    uint8_t* plane = heif_image_get_plane(image, heif_channel_interleaved, &stride);
    //xlog("stride=%d\n", stride);sss

    int y = 0;

    while (y < height) {
        const int high_scanline = min(y + num_scanlines - 1, height - 1);
        const int block_height = 1 + high_scanline - y;

        formatRecord->theRect.top = formatRecord->theRect32.top = y;
        formatRecord->theRect.bottom = formatRecord->theRect32.bottom = high_scanline + 1;

        //xlog("rect=(%d,%d)-(%d,%d)\n", formatRecord->theRect32.left, formatRecord->theRect32.top,
        //     formatRecord->theRect32.right, formatRecord->theRect32.bottom);

        formatRecord->advanceState();

        // Copy pixel data directly from Photoshop buffer to HEIF plane
        // Photoshop provides the correct format based on planes setting:
        // - save_alpha true: planes=4, formatRecord->data contains RGBA
        // - save_alpha false: planes=3, formatRecord->data contains RGB
        if (formatRecord->depth == 16) {
            unsigned16* src = (unsigned16*)formatRecord->data;
            unsigned16* dest = (unsigned16*)(plane + y * stride);
            for (int row = 0; row < block_height; ++row) {
                memcpy(dest, src, formatRecord->rowBytes);
                src += formatRecord->rowBytes / 2;  // Advance by pixels, not bytes
                dest += stride / 2;  // HEIF stride in pixels for 16-bit
            }
        } else {
            unsigned8* src = (unsigned8*)formatRecord->data;
            unsigned8* dest = plane + y * stride;
            for (int row = 0; row < block_height; ++row) {
                memcpy(dest, src, formatRecord->rowBytes);
                src += formatRecord->rowBytes;
                dest += stride;
            }
        }
        formatRecord->progressProc(y, height);
        y = high_scanline + 1;
    }

    formatRecord->progressProc(3, 10);

    // Apply 16-bit to 8-bit conversion if needed
    if (formatRecord->depth == 16 && save_alpha) {
        // For RGBA 16-bit, convert in-place
        unsigned16* pix = (unsigned16*)plane;
        size_t total_pixels = (size_t)width * (size_t)height * 4;  // RGBA
        for (size_t i = 0; i < total_pixels; ++i) {
            pix[i] = ByteSwap(RGB16ToRGB8(pix[i]));
        }
    } else if (formatRecord->depth == 16 && !save_alpha) {
        // For RGB 16-bit, convert in-place
        unsigned16* pix = (unsigned16*)plane;
        size_t total_pixels = (size_t)width * (size_t)height * 3;  // RGB
        for (size_t i = 0; i < total_pixels; ++i) {
            pix[i] = ByteSwap(RGB16ToRGB8(pix[i]));
        }
    }
    // For 8-bit, data is already in correct format from direct copy above

    if (opt.convertToSRGB && formatRecord->canUseICCProfiles && formatRecord->iCCprofileData && formatRecord->iCCprofileSize > 0) {
        cmsHPROFILE profileSrc = cmsOpenProfileFromMem(clr_profile_data, clr_profile_size);
        cmsHPROFILE profileSRGB = cmsCreate_sRGBProfile();
        cmsUInt32Number dataType = save_alpha ? TYPE_RGBA_8 : TYPE_RGB_8;
        cmsHTRANSFORM cms = cmsCreateTransform(profileSrc, dataType, profileSRGB, dataType, INTENT_PERCEPTUAL, 0);

        uint8_t* cur_dest_line = plane;
        for (size_t i = 0; i < height; ++i) {
            cmsDoTransform(cms, cur_dest_line, cur_dest_line, width);
            cur_dest_line += stride;
        }
        cmsDeleteTransform(cms);
        cmsCloseProfile(profileSrc);
        cmsCloseProfile(profileSRGB);
    }
    if (clr_profile_data) {
        free(clr_profile_data);
        clr_profile_data = 0;
    }

    myUnlockBuffer(formatRecord, bufferID);
    myFreeBuffer(formatRecord, bufferID);
    formatRecord->data = NULL;

    Handle exifData;
    PIGetEXIFData(exifData);
    string exif, xmp;
    PIGetXMP(xmp);
    HandleToString(exifData, exif);

    heif_image_handle* image_handle;
    heif_context_encode_image(ctx, image, encoder, nullptr, &image_handle);
    formatRecord->progressProc(9, 10);

    if (image_handle) {
        if (opt.saveExif) heif_context_add_exif_metadata(ctx, image_handle, exif.c_str(), exif.length());
        if (opt.saveXmp) heif_context_add_XMP_metadata(ctx, image_handle, xmp.c_str(), xmp.length());
        heif_context_set_primary_image(ctx, image_handle);
    }

    heif_encoder_release(encoder);

    heif_writer writer;
    writer.writer_api_version = 1;
    writer.write = jdp_heif_write;

    heif_context_write(ctx, &writer, formatRecord);
    heif_context_free(ctx);
    heif_image_release(image);

    formatRecord->progressProc(10, 10);
    *gResult = noErr;
}

void DoWriteContinue(FormatRecordPtr formatRecord) {
}

void DoWriteFinish(FormatRecordPtr formatRecord) {
    if (*gResult == noErr && gSavedPath[0] && !strstr(gSavedPath, "/private/var/folders")) {
        HEICParam opt;
        loadOptions(&opt);
        if (opt.revealInFinder) {
            NSString* path = [NSString stringWithUTF8String:gSavedPath];
            [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:[path stringByDeletingLastPathComponent]];
        }
    }
}
