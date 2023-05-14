echo off
setlocal enabledelayedexpansion
set excludeList=clean.bat build.bat Bit2Bin.exe config.vh zxdos_1Mb.xise zxdos_1Mb_pins.ucf zxdos_1Mb_top.prj zxdos_1Mb_top.ut zxdos_1Mb_top.v zxdos_1Mb_top.xst error.log

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
