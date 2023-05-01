mkdir xst
if errorlevel 1 exit /b 1
mkdir xst\projnav.tmp
if errorlevel 1 exit /b 1
%XILINX_BIN_PATH%\nt\xst -intstyle ise -ifn zxdosplus_top.xst -ofn zxdosplus_top.syr
if errorlevel 1 ("Error running xst, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\ngdbuild -intstyle ise -dd _zxdosplus -nt timestamp -uc zxdosplus_pins.ucf -p xc6slx25-ftg256-2 zxdosplus_top.ngc zxdosplus_top.ngd 
if errorlevel 1 ("Error running ngdbuild, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\map -intstyle ise -p xc6slx25-ftg256-2 -w -logic_opt off -ol high -t 1 -xt 3 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off -o zxdosplus_top_map.ncd zxdosplus_top.ngd zxdosplus_top.pcf 
if errorlevel 1 ("Error running map, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\par -w -intstyle ise -ol high -mt off zxdosplus_top_map.ncd zxdosplus_top.ncd zxdosplus_top.pcf 
if errorlevel 1 ("Error running par, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\trce -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml zxdosplus_top.twx zxdosplus_top.ncd -o zxdosplus_top.twr zxdosplus_top.pcf -ucf zxdosplus_pins.ucf 
if errorlevel 1 ("Error running trce, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\bitgen -intstyle ise -f zxdosplus_top.ut zxdosplus_top.ncd
if errorlevel 1 ("Error running bitgen, open the ISE project and synthesise from there for review." & exit /b 1)
Bit2Bin.exe zxdosplus_top.bit coreXX.zxd
if errorlevel 1 exit /b 1
copy coreXX.zxd ..\..\..\..\releases\VGA_31KHz\zxdosplus\ /y
if errorlevel 1 exit /b 1
timeout /t 10 /nobreak >nul
clean