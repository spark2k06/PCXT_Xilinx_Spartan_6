@ECHO OFF
PROMPT $p$g
PATH C:\DOS
SET TEMP=C:\DOS

GOTO %CONFIG%

:COMPAT
echo Mouse/raton: CTMOUSE.EXE
echo Para teclado espa¤ol escribe: keyb /E sp
echo Para cambiar a Tandy 1000 escribe: tandy
GOTO END

:COMPAT1
echo Mouse/raton: CTMOUSE.EXE
echo Para teclado espa¤ol escribe: keyb /E sp
echo Para cambiar a Tandy 1000 escribe: tandy
GOTO END

:EXTEND
LH CTMOUSE.EXE
echo Para teclado espa¤ol escribe: LH keyb /E sp
echo Para cambiar a Tandy 1000 escribe: tandy
GOTO END

:RAMDISK
LH CTMOUSE.EXE
C:\UTIL\SRDSK208\SRDISK 1024
echo Para teclado espa¤ol escribe: LH keyb /E sp
echo Para cambiar a Tandy 1000 escribe: tandy
GOTO END

:END 

if exist c:\dos\aaa*. del c:\dos\aaa*.




