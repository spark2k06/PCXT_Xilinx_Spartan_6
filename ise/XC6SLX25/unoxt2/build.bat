mkdir xst
if errorlevel 1 exit /b 1
mkdir xst\projnav.tmp
if errorlevel 1 exit /b 1
%XILINX_BIN_PATH%\nt\xst -intstyle ise -ifn unoxt2_top.xst -ofn unoxt2_top.syr
if errorlevel 1 ("Error running xst, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\ngdbuild -intstyle ise -dd _unoxt2 -nt timestamp -uc unoxt2_pins.ucf -p xc6slx25-ftg256-2 unoxt2_top.ngc unoxt2_top.ngd 
if errorlevel 1 ("Error running ngdbuild, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\map -intstyle ise -p xc6slx25-ftg256-2 -w -logic_opt off -ol high -t 1 -xt 3 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off -o unoxt2_top_map.ncd unoxt2_top.ngd unoxt2_top.pcf 
if errorlevel 1 ("Error running map, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\par -w -intstyle ise -ol high -mt off unoxt2_top_map.ncd unoxt2_top.ncd unoxt2_top.pcf 
if errorlevel 1 ("Error running par, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\trce -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml unoxt2_top.twx unoxt2_top.ncd -o unoxt2_top.twr unoxt2_top.pcf -ucf unoxt2_pins.ucf 
if errorlevel 1 ("Error running trce, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\bitgen -intstyle ise -f unoxt2_top.ut unoxt2_top.ncd
if errorlevel 1 ("Error running bitgen, open the ISE project and synthesise from there for review." & exit /b 1)
Bit2Bin.exe unoxt2_top.bit coreXX.xt2
if errorlevel 1 exit /b 1
copy coreXX.xt2 ..\..\..\releases\unoxt2\ /y
if errorlevel 1 exit /b 1
timeout /t 10 /nobreak >nul
clean