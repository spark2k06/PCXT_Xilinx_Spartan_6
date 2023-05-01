echo off
setlocal enabledelayedexpansion
set excludeList=clean.bat build.bat Bit2Bin.exe config.vh zxuno_2Mb_Ext.xise zxuno_2Mb_Ext_pins.ucf zxuno_2Mb_Ext_top.prj zxuno_2Mb_Ext_top.ut zxuno_2Mb_Ext_top.v zxuno_2Mb_Ext_top.xst error.log

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
