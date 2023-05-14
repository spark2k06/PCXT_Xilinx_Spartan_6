echo off
setlocal enabledelayedexpansion
set excludeList=clean.bat build.bat Bit2Bin.exe config.vh unoxt2.xise unoxt2_pins.ucf unoxt2_top.prj unoxt2_top.ut unoxt2_top.v unoxt2_top.xst error.log

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
