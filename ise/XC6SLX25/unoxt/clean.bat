echo off
setlocal enabledelayedexpansion
set excludeList=clean.bat build.bat Bit2Bin.exe config.vh unoxt.xise unoxt_pins.ucf unoxt_top.prj unoxt_top.ut unoxt_top.v unoxt_top.xst error.log

for /r %%i in (*) do (
    set exclude=
    for %%x in (%excludeList%) do (
        if "%%~nxi" == "%%x" set exclude=true
    )
    if not defined exclude del /f /s /q "%%i"
)
for /d /r %%i in (*) do (
    rd /s /q "%%i"
)
