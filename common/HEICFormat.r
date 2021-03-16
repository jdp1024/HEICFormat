//
// HEIC format write support plug-in for Adobe Photoshop
// Copyright (c) 2021 jdp.
// Distributed under GPLv3 license.
//

// The About box and resources are created in PIUtilities.r.
// You can easily override them, if you like.

#define plugInName			"HEIC Format"
#define plugInCopyrightYear	"2021"
#define plugInVersion       "0.0.1"
#define plugInDescription    "HEIC file export plug-in for Adobe Photoshop Version " plugInVersion "\nCopyright (c) 2021 jdp. No rights reserved."

//-------------------------------------------------------------------------------
//	Definitions -- Required by other resources in this rez file.
//-------------------------------------------------------------------------------

// Dictionary (aete) resources:

#define vendorName			"jdp"
#define plugInAETEComment 	"HEIC file format import plug-in"

#define plugInSuiteID		'sdK4'
#define plugInClassID		'texP'
#define plugInEventID		typeNull // must be this

//-------------------------------------------------------------------------------
//	Set up included files for Macintosh and Windows.
//-------------------------------------------------------------------------------

#include "PIDefines.h"

#ifdef __PIMac__
	#include "PIGeneral.r"
	#include "PIUtilities.r"
#elif defined(__PIWin__)
	#define Rez
	#include "PIGeneral.h"
	#include "PIUtilities.r"
#endif

#include "PITerminology.h"
#include "PIActions.h"

//-------------------------------------------------------------------------------
//	PiPL resource
//-------------------------------------------------------------------------------

resource 'PiPL' (ResourceID, plugInName " PiPL", purgeable)
{
    {
		Kind { ImageFormat },
		Name { plugInName },
		Version { (latestFormatVersion << 16) | latestFormatSubVersion },
        Category { "HEIC" },
        Priority { 1 },

		Component { ComponentNumber, plugInName },

		#ifdef __PIMac__
			CodeMacIntel64 { "PluginMain" },
		#else
			#if defined(_WIN64)
				CodeWin64X86 { "PluginMain" },
			#else
				CodeWin32X86 { "PluginMain" },
			#endif
		#endif

		// ClassID, eventID, aete ID, uniqueString:
		HasTerminology { plugInClassID, 
		                 plugInEventID, 
						 ResourceID, 
						 "9E3AF9BA-CBDD-4b26-920C-5FE8A5C61B59" },
		
		SupportedModes
		{
            noBitmap, noGrayScale,
            noIndexedColor, doesSupportRGBColor,
            noCMYKColor, noHSLColor,
            noHSBColor, noMultichannel,
            noDuotone, noLABColor },
		
        EnableInfo { "in (PSHOP_ImageMode, RGBMode, RGB48Mode, RGBColorMode) && PSHOP_ImageDepth == 8 || PSHOP_ImageDepth == 16" },

		// New for Photoshop 8, document sizes that are really big 
		// 32 bit row and columns, 2,000,000 current limit but we can handle more
		PlugInMaxSize { 2147483647, 2147483647 },

		// For older Photoshops that only support 30000 pixel documents, 
		// 16 bit row and columns
		FormatMaxSize { { 32767, 32767 } },

		FormatMaxChannels { {   1, 24, 24, 24, 24, 24, 
							   24, 24, 24, 24, 24, 24 } },
	
		FmtFileType { 'HEIC', '8BIM' },
        FilteredExtensions  { { 'heic' } },
        WriteExtensions { { 'heic' } },
		FormatFlags { fmtSavesImageResources, 
		              fmtCannotRead,
					  fmtCanWrite,
                      fmtCanWriteIfRead,
					  fmtCanWriteTransparency, 
					  fmtCannotCreateThumbnail },
		FormatICCFlags { iccCannotEmbedGray,
						 iccCannotEmbedIndexed,
						 iccCanEmbedRGB,
						 iccCannotEmbedCMYK }
		},
	};


//-------------------------------------------------------------------------------
//	Dictionary (scripting) resource
//-------------------------------------------------------------------------------

resource 'aete' (ResourceID, plugInName " dictionary", purgeable)
{
	1, 0, english, roman,									/* aete version and language specifiers */
	{
		vendorName,											/* vendor suite name */
		"HEIC Format save plug-in",							/* optional description */
		plugInSuiteID,										/* suite ID */
		1,													/* suite code, must be 1 */
		1,													/* suite level, must be 1 */
		{},													/* structure for filters */
		{													/* non-filter plug-in class here */
			vendorName " " plugInName,						/* unique class name */
			plugInClassID,									/* class ID, must be unique or Suite ID */
			plugInAETEComment,								/* optional description */
			{												/* define inheritance */
				"<Inheritance>",							/* must be exactly this */
				keyInherits,								/* must be keyInherits */
				classFormat,								/* parent: Format, Import, Export */
				"parent class format",						/* optional description */
				flagsSingleProperty,						/* if properties, list below */
							
				/* no properties */
			},
			{}, /* elements (not supported) */
			/* class descriptions */
		},
		{}, /* comparison ops (not supported) */
		{}	/* any enumerations */
	}
};

//-------------------------------------------------------------------------------
// end TextFormat.r
