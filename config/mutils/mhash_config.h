/* mhash's configuration for AmigaOS 3 with libnix (m68k, big-endian): what
 * mhash's configure would find there. Every hash wxHexEditor offers is on.
 * Copyright (c) 2026 AmiCradle Team. GPL 2 or later, like wxHexEditor. */
#ifndef MHASH_AMIGA_CONFIG_H
#define MHASH_AMIGA_CONFIG_H

#define ENABLE_ADLER32 1
#define ENABLE_CRC32 1
#define ENABLE_GOST 1
#define ENABLE_HAVAL 1
#define ENABLE_MD2 1
#define ENABLE_MD4 1
#define ENABLE_MD5 1
#define ENABLE_RIPEMD 1
#define ENABLE_SHA1 1
#define ENABLE_SHA256_SHA224 1
#define ENABLE_SHA512_SHA384 1
#define ENABLE_SNEFRU 1
#define ENABLE_TIGER 1
#define ENABLE_WHIRLPOOL 1

/* the C library headers libnix has */
#define HAVE_ASSERT_H 1
#define HAVE_CTYPE_H 1
#define HAVE_ERRNO_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_LIMITS_H 1
#define HAVE_STDBOOL_H 1
#define HAVE_STDINT_H 1
#define HAVE_STDIO_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_STRINGS_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_UNISTD_H 1
#define HAVE_MEMMOVE 1
#define HAVE_MEMSET 1
#define HAVE_MALLOC 1
#define HAVE__BOOL 1

/* the 68000 family is big-endian */
#define WORDS_BIGENDIAN 1

#define PACKAGE "mhash"
#define VERSION "0.9.9"
#define PROTOTYPES 1
#define STDC_HEADERS 1

#endif
