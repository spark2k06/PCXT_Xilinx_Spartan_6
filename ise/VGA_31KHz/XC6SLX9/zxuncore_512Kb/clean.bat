echo off
setlocal enabledelayedexpansion
set excludeList=clean.bat build.bat Bit2Bin.exe config.vh zxuncore_512Kb.xise zxuncore_512Kb_pins.ucf zxuncore_512Kb_top.prj zxuncore_512Kb_top.ut zxuncore_512Kb_top.v zxuncore_512Kb_top.xst error.log

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
