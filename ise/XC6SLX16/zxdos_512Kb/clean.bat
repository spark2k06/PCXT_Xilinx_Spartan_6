echo off
setlocal enabledelayedexpansion
set excludeList=clean.bat build.bat Bit2Bin.exe config.vh zxdos_512Kb.xise zxdos_512Kb_pins.ucf zxdos_512Kb_top.prj zxdos_512Kb_top.ut zxdos_512Kb_top.v zxdos_512Kb_top.xst error.log

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
