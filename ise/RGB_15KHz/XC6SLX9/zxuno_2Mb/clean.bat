echo off
setlocal enabledelayedexpansion
set excludeList=clean.bat build.bat Bit2Bin.exe config.vh zxuno_2Mb.xise zxuno_2Mb_pins.ucf zxuno_2Mb_top.prj zxuno_2Mb_top.ut zxuno_2Mb_top.v zxuno_2Mb_top.xst error.log

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
