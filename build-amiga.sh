#!/bin/sh
# Builds wxHexEditor for AmigaOS 3 with a stove: 68040, soft float with the
# FPU taken when there is one (fpuauto), on the GFOpenWX Toolkit.
#   STOVE=.../stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh
#   (WXT_SRC=... to use a toolkit tree already on disk)
# wxHexEditor, the toolkit and fpuauto are fetched at the commits
# hexeditor.lock gives; nothing third-party is kept here. The build tree is
# kept, so a run that stops at BUDGET_TOTAL seconds goes on next time.
# OUT gets wxHexEditor when it links.
# Copyright (c) 2026 AmiCradle Team. GPL 2 or later, like wxHexEditor.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/hexeditor.lock"
STOVE=${STOVE:-"$HOME/AmiCradle/stoves/os32-gcc16-open6"}
WORK="${WORK:-$HERE/build}"; OUT="${OUT:-$WORK/out}"; JOBS=${JOBS:-12}
TC="$STOVE/prefix"; PATH="$TC/bin:$PATH"; export PATH
mkdir -p "$WORK/deps" "$OUT"
t0=$(date +%s)

# a repository at one commit, fetched once (SPARSE: only those folders)
fetch() {
    d="$WORK/deps/$1"
    if [ "$(git -C "$d" rev-parse HEAD 2>/dev/null)" != "$3" ]; then
        rm -rf "${d:?}"; mkdir -p "$d"
        git -C "$d" init -q
        if [ -n "${4:-}" ]; then
            git -C "$d" config core.sparseCheckout true
            echo "$4" > "$d/.git/info/sparse-checkout"
            git -C "$d" fetch -q --depth 1 --filter=blob:none "$2" "$3"
        else
            git -C "$d" fetch -q --depth 1 "$2" "$3"
        fi
        git -C "$d" checkout -q FETCH_HEAD
        [ "$(git -C "$d" rev-parse HEAD)" = "$3" ] || { echo "$1: commit mismatch"; exit 1; }
    fi
}

# --- the toolkit's SDK, again only when its tree changed ---------------------
if [ -z "${WXT_SRC:-}" ]; then fetch gfopenwxtoolkit "$WXT_REPO" "$WXT_COMMIT"; WXT_SRC="$WORK/deps/gfopenwxtoolkit"; fi
WXB="$WORK/gfopenwx"
WXREV=$( (git -C "$WXT_SRC" rev-parse HEAD 2>/dev/null; git -C "$WXT_SRC" diff HEAD 2>/dev/null) | sha256sum | cut -c1-16)
if [ ! -x "$WXB/out/sdk/bin/wx-config" ] || [ "$(cat "$WXB/out/.rev" 2>/dev/null)" != "$WXREV" ]; then
    STOVE="$STOVE" WORK="$WXB" OUT="$WXB/out" JOBS=$JOBS sh "$WXT_SRC/build-amiga.sh" > "$WORK.wx.log" 2>&1 || { tail -40 "$WORK.wx.log"; exit 1; }
    [ -x "$WXB/out/sdk/bin/wx-config" ] || { tail -40 "$WORK.wx.log"; echo "no toolkit SDK"; exit 1; }
    echo "$WXREV" > "$WXB/out/.rev"
fi
echo "toolkit: $(( $(date +%s) - t0 )) s"
WXC="$WXB/out/sdk/bin/wx-config"

# --- fpuauto: libfpuauto.a and its link specs ---------------------------------
fetch fpuauto "$FPA_REPO" "$FPA_COMMIT" "/common/fpuauto/"
FA="$WORK/deps/fpuauto/common/fpuauto"; FAL="$WORK/fpuauto"
if [ ! -f "$FAL/libfpuauto.a" ] || [ "$(cat "$FAL/.rev" 2>/dev/null)" != "$FPA_COMMIT" ]; then
    rm -rf "$FAL"; mkdir -p "$FAL/obj"
    m68k-amigaos-gcc -m68040 -DFPUAUTO_COMMON -c "$FA/fpuauto.S" -o "$FAL/obj/fa_common.o"
    for n in $(sed 's/^--wrap=//' "$FA/fpuauto.wraps"); do
        m68k-amigaos-gcc -m68040 -DR_$n -c "$FA/fpuauto.S" -o "$FAL/obj/fa_$n.o"
    done
    m68k-amigaos-ar rcs "$FAL/libfpuauto.a" "$FAL"/obj/fa_*.o
    echo "$FPA_COMMIT" > "$FAL/.rev"
fi

# --- wxHexEditor at its pinned commit, with patches/ --------------------------
SRC="$WORK/wxHexEditor"
PSUM=$(cat "$HERE"/patches/*.patch | sha256sum | cut -c1-16)
if [ "$(cat "$SRC/.patched" 2>/dev/null)" != "$WXHE_COMMIT-$PSUM" ]; then
    rm -rf "$SRC"; mkdir -p "$SRC"
    git -C "$SRC" init -q
    git -C "$SRC" fetch -q --depth 1 "$WXHE_GIT" "$WXHE_COMMIT"
    git -C "$SRC" checkout -q FETCH_HEAD
    [ "$(git -C "$SRC" rev-parse HEAD)" = "$WXHE_COMMIT" ] || { echo "commit mismatch"; exit 1; }
    for p in "$HERE"/patches/*.patch; do
        patch -s -d "$SRC" -p1 < "$p" || { echo "patch failed: $p"; exit 1; }
    done
    # udis86's opcode tables, made on the build host as its own build does
    python3 -E -s "$SRC/udis86/scripts/ud_itab.py" "$SRC/udis86/docs/x86/optable.xml" "$SRC/udis86/libudis86" > /dev/null
    echo "$WXHE_COMMIT-$PSUM" > "$SRC/.patched"
    rm -rf "$WORK/obj"
fi

# --- one Makefile: udis86, mhash, the program --------------------------------
LATE=""
if m68k-amigaos-gcc -fno-late-combine-instructions -S -o /dev/null -x c /dev/null 2>/dev/null; then LATE="-fno-late-combine-instructions"; fi
CF="-noixemul -m68040 -O2 -fno-delete-null-pointer-checks $LATE -DNDEBUG"
O="$WORK/obj"; mkdir -p "$O"
UD="decode itab syn syn-att syn-intel udis86"
MH="mhash stdfns keygen_hex keygen_mcrypt keygen_asis keygen keygen_s2k crc32 adler32 md2 md4 md5 ripemd sha1 sha256_sha224 sha512_sha384 tiger tiger_sboxes haval gosthash whirlpool snefru"
APP="HexEditorGui FAL HexDialogs HexPanels HexEditorApp HexEditor HexEditorCtrl/HexEditorCtrl HexEditorCtrl/wxHexCtrl/TagDialogGui HexEditorCtrl/wxHexCtrl/wxHexCtrl HexEditorCtrl/wxHexCtrl/Tag HexEditorCtrl/HexEditorCtrlGui HexEditorFrame"
M="$O/Makefile"
{
    echo "UDF = $CF -std=gnu99 -I$SRC/udis86/libudis86"
    echo "MHF = $CF -std=gnu99 -I$HERE/config -I$SRC/mhash/include -I$SRC/mhash/lib"
    echo "CXXF = $CF -std=gnu++17 $("$WXC" --cxxflags) -I$HERE/config -I$SRC/udis86 -I$SRC/mhash/include -Wno-deprecated-declarations"
    U=""; for f in $UD; do U="$U ud_$f.o"; printf 'ud_%s.o: %s\n\tm68k-amigaos-gcc $(UDF) -MMD -c $< -o $@\n' "$f" "$SRC/udis86/libudis86/$f.c"; done
    H=""; for f in $MH; do H="$H mh_$f.o"; printf 'mh_%s.o: %s\n\tm68k-amigaos-gcc $(MHF) -MMD -c $< -o $@\n' "$f" "$SRC/mhash/lib/$f.c"; done
    A=""; for f in $APP; do o="app_$(echo "$f" | tr / _).o"; A="$A $o"; printf '%s: %s\n\tm68k-amigaos-g++ $(CXXF) -MMD -c $< -o $@\n' "$o" "$SRC/src/$f.cpp"; done
    printf 'amiga_stack.o: %s\n\tm68k-amigaos-gcc $(UDF) -c $< -o $@\n' "$HERE/compat/amiga_stack.c"
    echo "libudis86.a:$U"; printf '\trm -f $@; m68k-amigaos-ar rcs $@ $^\n'
    echo "libmhash.a:$H"; printf '\trm -f $@; m68k-amigaos-ar rcs $@ $^\n'
    echo "APPOBJS =$A amiga_stack.o"
    echo "all: libudis86.a libmhash.a \$(APPOBJS)"
    echo "-include *.d"
} > "$M"
left=$(( ${BUDGET_TOTAL:-840} - ($(date +%s) - t0) ))
[ "$left" -gt 60 ] || { echo "no time left for wxHexEditor this run"; exit 0; }
set +e
(cd "$O" && timeout "$left" nice -n 19 make -k -j"$JOBS" all > make.log 2>&1)
rc=$?
set -e
grep -E 'error|Error' "$O/make.log" | head -60
[ "$rc" = 0 ] || { [ "$rc" = 124 ] && echo "out of time: run again to go on"; tail -20 "$O/make.log"; echo "compile: $(( $(date +%s) - t0 )) s"; exit "$rc"; }

# --- the link: soft-float specs, then fpuauto's ------------------------------
# shellcheck disable=SC2046
m68k-amigaos-g++ -noixemul -m68040 -specs="$HERE/scripts/m68k-soft-m68040.specs" -specs="$FA/fpuauto.specs" -L"$FAL" \
    -o "$O/wxHexEditor.debug" $(cd "$O" && for f in $(sed -n 's/^APPOBJS =//p' Makefile); do echo "$O/$f"; done) \
    "$O/libudis86.a" "$O/libmhash.a" $("$WXC" --libs std,aui) > "$O/link.log" 2>&1 || { head -60 "$O/link.log"; exit 1; }
m68k-amigaos-strip -o "$OUT/wxHexEditor" "$O/wxHexEditor.debug"
ls -l "$OUT/wxHexEditor"
echo "fpuauto: $(m68k-amigaos-nm "$O/wxHexEditor.debug" | grep -c ' T ___wrap_') wrapped routines"
echo "total: $(( $(date +%s) - t0 )) s"
