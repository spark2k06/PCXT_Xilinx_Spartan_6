mkdir xst
if errorlevel 1 exit /b 1
mkdir xst\projnav.tmp
if errorlevel 1 exit /b 1
%XILINX_BIN_PATH%\nt\xst -intstyle ise -ifn zxuncore_2Mb_top.xst -ofn zxuncore_2Mb_top.syr
if errorlevel 1 ("Error running xst, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc zxuncore_2Mb_pins.ucf -p xc6slx9-tqg144-2 zxuncore_2Mb_top.ngc zxuncore_2Mb_top.ngd 
if errorlevel 1 ("Error running ngdbuild, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\map -intstyle ise -p xc6slx9-tqg144-2 -w -logic_opt off -ol high -t 1 -xt 3 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off -o zxuncore_2Mb_top_map.ncd zxuncore_2Mb_top.ngd zxuncore_2Mb_top.pcf 
if errorlevel 1 ("Error running map, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\par -w -intstyle ise -ol high -mt off zxuncore_2Mb_top_map.ncd zxuncore_2Mb_top.ncd zxuncore_2Mb_top.pcf 
if errorlevel 1 ("Error running par, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\trce -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml zxuncore_2Mb_top.twx zxuncore_2Mb_top.ncd -o zxuncore_2Mb_top.twr zxuncore_2Mb_top.pcf -ucf zxuncore_2Mb_pins.ucf 
if errorlevel 1 ("Error running trce, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\bitgen -intstyle ise -f zxuncore_2Mb_top.ut zxuncore_2Mb_top.ncd
if errorlevel 1 ("Error running bitgen, open the ISE project and synthesise from there for review." & exit /b 1)
Bit2Bin.exe zxuncore_2Mb_top.bit coreXX.zx1
if errorlevel 1 exit /b 1
copy coreXX.zx1 ..\..\..\releases\zxuncore_2Mb\ /y
if errorlevel 1 exit /b 1
timeout /t 10 /nobreak >nul
clean