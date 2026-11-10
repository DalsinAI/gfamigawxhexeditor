/* arexx.rexx: wxHexEditor's ARexx port (WXHEXEDITOR.1). Start wxHexEditor first, with
 * RexxMast running. Prints PASS or FAIL for each check, then QUITs it and
 * checks that the port has gone. rx tests/arexx.rexx [FILE]  (default S:Startup-Sequence)
 * Copyright (c) 2026 AmiCradle Team */
OPTIONS RESULTS
PARSE ARG file
bad = 0
IF ~SHOW('P', 'WXHEXEDITOR.1') THEN DO
    SAY 'FAIL wxHexEditor is not running (no WXHEXEDITOR.1)'
    EXIT 20
END
ADDRESS 'WXHEXEDITOR.1'

'VERSION'
CALL check 'VERSION', rc = 0 & POS('wxHexEditor ', result) = 1
'HELP'
CALL check 'HELP', rc = 0 & POS('QUIT', result) > 0 & POS('OPEN', result) > 0 & POS('GOTO', result) > 0 & POS('GETPOS', result) > 0 & POS('GETSIZE', result) > 0
'FAULT 205'
CALL check 'FAULT', rc = 0 & result ~= ''
'NOSUCH'
CALL check 'unknown command', rc = 20
'DEACTIVATE'
CALL check 'DEACTIVATE', rc = 0
'ACTIVATE'
CALL check 'ACTIVATE', rc = 0
IF file = '' THEN file = 'S:Startup-Sequence'
'OPEN' '"'file'"'
CALL check 'OPEN', rc = 0
'GETSIZE'
size = result
CALL check 'GETSIZE', rc = 0 & DATATYPE(size, 'W') & size > 16
'GOTO 16'
CALL check 'GOTO 16', rc = 0
'GETPOS'
CALL check 'GETPOS', rc = 0 & result = 16
'GOTO 0x8'
'GETPOS'
CALL check 'GOTO 0x8', rc = 0 & result = 8
'GOTO nonsense'
CALL check 'GOTO bad number', rc = 10
'OPEN NoSuchDrawer/none.bin'
CALL check 'OPEN missing', rc = 10
'QUIT'
CALL check 'QUIT', rc = 0
DO i = 1 TO 30
    IF ~SHOW('P', 'WXHEXEDITOR.1') THEN LEAVE
    ADDRESS COMMAND 'Wait 1'
END
CALL check 'port gone after QUIT', ~SHOW('P', 'WXHEXEDITOR.1')
IF bad = 0 THEN SAY 'wxhexeditor arexx: ALL PASS'
ELSE SAY 'wxhexeditor arexx:' bad 'FAILED'
EXIT bad

check: PARSE ARG what, ok
IF ok THEN SAY 'PASS' what
ELSE DO
    SAY 'FAIL' what '(rc' rc')'
    bad = bad + 1
END
RETURN
