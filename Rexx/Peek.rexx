/* Peek.rexx: wxHexEditor opens a file and goes to an offset.
   rx Peek.rexx SYS:C/Dir 0x100   (wxHexEditor running) */
OPTIONS RESULTS
PARSE ARG file offset
IF offset = '' THEN offset = 0
IF ~SHOW('P', 'WXHEXEDITOR.1') THEN DO
    SAY 'wxHexEditor is not running.'
    EXIT 5
END
ADDRESS 'WXHEXEDITOR.1'
IF file ~= '' THEN 'OPEN' '"'file'"'
'GETSIZE'
SAY 'Size:' RESULT 'bytes'
'GOTO' offset
'GETPOS'
SAY 'At:' RESULT
