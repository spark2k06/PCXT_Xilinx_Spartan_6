mkdir xst
if errorlevel 1 exit /b 1
mkdir xst\projnav.tmp
if errorlevel 1 exit /b 1
%XILINX_BIN_PATH%\nt\xst -intstyle ise -ifn unoxt_top.xst -ofn unoxt_top.syr
if errorlevel 1 ("Error running xst, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\ngdbuild -intstyle ise -dd _unoxt -nt timestamp -uc unoxt_pins.ucf -p xc6slx25-ftg256-2 unoxt_top.ngc unoxt_top.ngd 
if errorlevel 1 ("Error running ngdbuild, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\map -intstyle ise -p xc6slx25-ftg256-2 -w -logic_opt off -ol high -t 1 -xt 3 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off -o unoxt_top_map.ncd unoxt_top.ngd unoxt_top.pcf 
if errorlevel 1 ("Error running map, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\par -w -intstyle ise -ol high -mt off unoxt_top_map.ncd unoxt_top.ncd unoxt_top.pcf 
if errorlevel 1 ("Error running par, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\trce -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml unoxt_top.twx unoxt_top.ncd -o unoxt_top.twr unoxt_top.pcf -ucf unoxt_pins.ucf 
if errorlevel 1 ("Error running trce, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\bitgen -intstyle ise -f unoxt_top.ut unoxt_top.ncd
if errorlevel 1 ("Error running bitgen, open the ISE project and synthesise from there for review." & exit /b 1)
Bit2Bin.exe unoxt_top.bit coreXX.zxt
if errorlevel 1 exit /b 1
copy coreXX.zxt ..\..\..\releases\unoxt\ /y
if errorlevel 1 exit /b 1
timeout /t 10 /nobreak >nul
clean