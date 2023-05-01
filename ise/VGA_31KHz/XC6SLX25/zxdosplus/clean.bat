echo off
setlocal enabledelayedexpansion
set excludeList=clean.bat build.bat Bit2Bin.exe config.vh zxdosplus.xise zxdosplus_pins.ucf zxdosplus_top.prj zxdosplus_top.ut zxdosplus_top.v zxdosplus_top.xst error.log

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
