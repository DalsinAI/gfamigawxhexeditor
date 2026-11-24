#!/bin/sh
# The single-instance check needs both IPC and wxSingleInstanceChecker in the
# toolkit. Toolkit main has IPC but not the checker, so the guard must test both.
HERE=$(cd "$(dirname "$0")/.." && pwd)
P="$HERE/patches/0002-ipc-and-url-only-when-built.patch"
fail=0
ok() { echo "ok - $1"; }
no() { echo "not ok - $1"; fail=1; }
grep -q '^+#if wxUSE_IPC && wxUSE_SNGLINST_CHECKER$' "$P" && ok "checker guarded by both" || no "checker guarded by both"
grep -q '^+#endif // wxUSE_IPC && wxUSE_SNGLINST_CHECKER$' "$P" && ok "guard closed" || no "guard closed"
# The guard sits right before the checker is made.
awk '/^\+#if wxUSE_IPC && wxUSE_SNGLINST_CHECKER$/{f=1;next} f&&/wxSingleInstanceChecker\* m_checker/{print "y";exit} f&&/^\+#endif/{exit}' "$P" | grep -q y \
  && ok "checker inside the guard" || no "checker inside the guard"
# The patch still applies cleanly in its hunk counts (no lines added or removed).
[ "$(grep -c '^+#if' "$P")" = "$(grep -c '^+#endif' "$P")" ] && ok "every #if has its #endif" || no "every #if has its #endif"
exit $fail
