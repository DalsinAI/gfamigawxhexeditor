/* A Shell gives 4 KB of stack; libnix's startup sets this much up instead.
 * wxWidgets' event handling and wxHexEditor's dialogs nest deeply.
 * Copyright (c) 2026 AmiCradle Team. GPL 2 or later, like wxHexEditor. */
unsigned long __stack = 1024 * 1024;
static const char version[] __attribute__((used)) = "$VER: wxHexEditor 0.25 Amiga (05.11.2026)";
