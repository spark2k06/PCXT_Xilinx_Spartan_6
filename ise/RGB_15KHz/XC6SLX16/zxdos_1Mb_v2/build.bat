mkdir xst
if errorlevel 1 exit /b 1
mkdir xst\projnav.tmp
if errorlevel 1 exit /b 1
%XILINX_BIN_PATH%\nt\xst -intstyle ise -ifn zxdos_1Mb_top.xst -ofn zxdos_1Mb_top.syr
if errorlevel 1 ("Error running xst, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\ngdbuild -intstyle ise -dd _zxdos_1Mb -nt timestamp -uc zxdos_1Mb_pins.ucf -p xc6slx16-ftg256-2 zxdos_1Mb_top.ngc zxdos_1Mb_top.ngd 
if errorlevel 1 ("Error running ngdbuild, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\map -intstyle ise -p xc6slx16-ftg256-2 -w -logic_opt off -ol high -t 1 -xt 3 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off -o zxdos_1Mb_top_map.ncd zxdos_1Mb_top.ngd zxdos_1Mb_top.pcf 
if errorlevel 1 ("Error running map, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\par -w -intstyle ise -ol high -mt off zxdos_1Mb_top_map.ncd zxdos_1Mb_top.ncd zxdos_1Mb_top.pcf 
if errorlevel 1 ("Error running par, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\trce -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml zxdos_1Mb_top.twx zxdos_1Mb_top.ncd -o zxdos_1Mb_top.twr zxdos_1Mb_top.pcf -ucf zxdos_1Mb_pins.ucf 
if errorlevel 1 ("Error running trce, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\bitgen -intstyle ise -f zxdos_1Mb_top.ut zxdos_1Mb_top.ncd
if errorlevel 1 ("Error running bitgen, open the ISE project and synthesise from there for review." & exit /b 1)
Bit2Bin.exe zxdos_1Mb_top.bit coreXX_black.zx2
if errorlevel 1 exit /b 1
copy coreXX_black.zx2 ..\..\..\..\releases\RGB_15KHz\zxdos_1Mb\ /y
if errorlevel 1 exit /b 1
timeout /t 10 /nobreak >nul
clean