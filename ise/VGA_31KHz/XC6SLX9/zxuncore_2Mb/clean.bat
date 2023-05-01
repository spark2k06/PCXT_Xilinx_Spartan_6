echo off
setlocal enabledelayedexpansion
set excludeList=clean.bat build.bat Bit2Bin.exe config.vh zxuncore_2Mb.xise zxuncore_2Mb_pins.ucf zxuncore_2Mb_top.prj zxuncore_2Mb_top.ut zxuncore_2Mb_top.v zxuncore_2Mb_top.xst error.log

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
