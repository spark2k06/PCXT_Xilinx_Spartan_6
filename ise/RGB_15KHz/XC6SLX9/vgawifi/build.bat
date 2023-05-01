mkdir xst
if errorlevel 1 exit /b 1
mkdir xst\projnav.tmp
if errorlevel 1 exit /b 1
%XILINX_BIN_PATH%\nt\xst -intstyle ise -ifn vgawifi_top.xst -ofn vgawifi_top.syr
if errorlevel 1 ("Error running xst, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc vgawifi_pins.ucf -p xc6slx9-tqg144-2 vgawifi_top.ngc vgawifi_top.ngd 
if errorlevel 1 ("Error running ngdbuild, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\map -intstyle ise -p xc6slx9-tqg144-2 -w -logic_opt off -ol high -t 1 -xt 3 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off -o vgawifi_top_map.ncd vgawifi_top.ngd vgawifi_top.pcf 
if errorlevel 1 ("Error running map, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\par -w -intstyle ise -ol high -mt off vgawifi_top_map.ncd vgawifi_top.ncd vgawifi_top.pcf 
if errorlevel 1 ("Error running par, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\trce -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml vgawifi_top.twx vgawifi_top.ncd -o vgawifi_top.twr vgawifi_top.pcf -ucf vgawifi_pins.ucf 
if errorlevel 1 ("Error running trce, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\bitgen -intstyle ise -f vgawifi_top.ut vgawifi_top.ncd
if errorlevel 1 ("Error running bitgen, open the ISE project and synthesise from there for review." & exit /b 1)
Bit2Bin.exe vgawifi_top.bit coreXX.zx1
if errorlevel 1 exit /b 1
copy coreXX.zx1 ..\..\..\..\releases\RGB_15KHz\vgawifi\ /y
if errorlevel 1 exit /b 1
timeout /t 10 /nobreak >nul
clean