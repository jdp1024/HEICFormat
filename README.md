HEIC Format Plug-in For Adobe Photoshop
===
A plug-in for Photoshop that adds functionality to save the document as HEIC format.

License
---
This software is written for fun by jdp, 2021 and licensed under GPLv3.

How to use
---
Copy HEICFormat.plugin to "/Applications/Adobe Photoshop NNNN/Plug-ins/Filters" where NNNN is the major version of Adobe Photoshop. You may need the administrator right to do that.

Check 'About plugins' menu to see if the plug-in is activated: a menu item 'HEIC Format...' is added, you can use it to bring up the settings window.

If it is not there, check if the correct permission is set, you can re-enforce it by the following command in the terminal:

```
xattr -cr "/Applications/Adobe Photoshop NNNN/Plug-ins/Filters/HEICFormat.plugin"
chmod a+x "/Applications/Adobe Photoshop NNNN/Plug-ins/Filters/HEICFormat.plugin/Contents/MacOS/HEICFormat"
```

If everything works, you will see 'HEIC Format' in the file type list in the Save As dialog.

Third-party softwares
---
This software uses the following third-party softwares:

- [libheif][1]
- [x265][2]
- [LittleCMS 2][4] and its [fast float plug-in][6]

Use brew to install the development headers and libraries.

```
brew install libheif x265
```

For LittleCMS 2, you must compile from the source code to enable the fast float plugin:

```
./configure --with-fastfloat
make && make install
```

This software is under the framework of [Adobe Photoshop SDK][5], you must download it to compile the source code.

Notes about Options
---
- Reveal in Finder: only works when saving to a new file. Not working when to overwrite an existing file.
- Always convert to sRGB: this will override the 'Embed color profile' in the 'Save As' dialog.
- Don't ask me every time: quiet mode, use the settings for the HEIC encoder. If you want to change the settings, you can use the menu by visiting 'About Plugins -> HEIC Format...'.

Features
---
- Works as Photoshop plug-in with a simple settings UI.
- Compatible with OS/X's Preview and iPhone's Photo.
- Exports to HEIC format.
- Adjustable quality (0-100).
- Keeps alpha channel or not.
- Keeps color profile or not.
- Keeps EXIF and XMP data or not.
- Converts to sRGB.

Limitations and todo's
---
- Currently for OS/X or macOS 10.13+ only. Windows version to be done.
- Uses the default settings and preset of x.265. Currently not customizable.
- No thumbnails support.
- Will crash Photoshop 22.3 if color profile is embedded (not my bug). Convert to sRGB to avoid.
- Not scriptable, yet.

[1]: https://github.com/strukturag/libheif
[2]: https://www.videolan.org/developers/x265.html
[3]: https://github.com/fnordware/SuperPNG
[4]: https://github.com/mm2/Little-CMS
[5]: https://console.adobe.io/downloads
[6]: https://www.littlecms.com/plugin
