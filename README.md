# GF Amiga wxHexEditor

wxHexEditor for AmigaOS 3 (68040, soft float with the FPU taken when there is one), on the GFOpenWX Toolkit (wxWidgets on GFOpenLayout).

wxHexEditor is fetched at build time at the commit `hexeditor.lock` pins, and `patches/` is applied to it; nothing third-party is kept in this repository. The mhash and udis86 libraries come from wxHexEditor's own tree.

## Status

Builds and runs in a lab (6 Nov 2026): opens a file from the command line and shows its bytes. The column headers come out in a smaller font than the hex area (the toolkit does not yet take wxStaticText fonts), so they do not line up.

## Building

```
STOVE=~/AmiCradle/stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh
```

The first run fetches the GFOpenWX Toolkit and fpuauto at the commits `hexeditor.lock` pins and builds the toolkit SDK, then wxHexEditor for what is left of 840 s; run it again and it goes on from where it stopped. `out/wxHexEditor` appears when it links.

| Where | What |
|---|---|
| `patches/` | wxHexEditor's changes for the Amiga: file access without ptrace, the compare buffer on the heap, no update check unless asked for, the first-run licence box once the window is up |
| `config/` | mhash's configuration for libnix (big-endian) |
| `compat/` | the stack the program asks for |
| `scripts/` | the 68040 soft-float link specs |

## ARexx

wxHexEditor has an ARexx port, `WXHEXEDITOR.1` (`WXHEXEDITOR.2` for a second copy), from the GFOpenWX Toolkit's `wxARexxPort` on arexx.class (`compat/rexx_amiga.cpp`, patch 0007).

| Command | Does |
| --- | --- |
| `OPEN FILE/A` | open a file in a new tab |
| `SAVE` | save the front tab's file |
| `GOTO OFFSET/A` | move the cursor to OFFSET (decimal, or `0x...` hex) |
| `GETPOS` | RESULT: the cursor's offset |
| `GETSIZE` | RESULT: the front tab's file length |
| `QUIT`, `ACTIVATE`, `DEACTIVATE`, `VERSION`, `HELP`, `FAULT` | the toolkit's standard commands |

RC 10 when there is no tab, or the file could not be opened or saved.

```
/* wxHexEditor: look at the end of a file */
OPTIONS RESULTS
ADDRESS 'WXHEXEDITOR.1'
'OPEN Work:Data/dump.bin'
'GETSIZE'
'GOTO' MAX(0, result - 256)
```

## Licence

wxHexEditor is GPL v2 or later; the patches and build files here are under the same licence.

Designed, tested and delivered by The AmiCradle Team.
Copyright (c) 2026 AmiCradle Team
