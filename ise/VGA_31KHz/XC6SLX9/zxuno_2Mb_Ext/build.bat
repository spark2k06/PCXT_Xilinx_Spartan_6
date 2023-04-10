mkdir xst
if errorlevel 1 exit /b 1
mkdir xst\projnav.tmp
if errorlevel 1 exit /b 1
%XILINX_BIN_PATH%\nt\xst -intstyle ise -ifn zxuno_2Mb_Ext_top.xst -ofn zxuno_2Mb_Ext_top.syr
if errorlevel 1 ("Error running xst, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc zxuno_2Mb_Ext_pins.ucf -p xc6slx9-tqg144-2 zxuno_2Mb_Ext_top.ngc zxuno_2Mb_Ext_top.ngd 
if errorlevel 1 ("Error running ngdbuild, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\map -intstyle ise -p xc6slx9-tqg144-2 -w -logic_opt off -ol high -t 1 -xt 3 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off -o zxuno_2Mb_Ext_top_map.ncd zxuno_2Mb_Ext_top.ngd zxuno_2Mb_Ext_top.pcf 
if errorlevel 1 ("Error running map, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\par -w -intstyle ise -ol high -mt off zxuno_2Mb_Ext_top_map.ncd zxuno_2Mb_Ext_top.ncd zxuno_2Mb_Ext_top.pcf 
if errorlevel 1 ("Error running par, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\trce -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml zxuno_2Mb_Ext_top.twx zxuno_2Mb_Ext_top.ncd -o zxuno_2Mb_Ext_top.twr zxuno_2Mb_Ext_top.pcf -ucf zxuno_2Mb_Ext_pins.ucf 
if errorlevel 1 ("Error running trce, open the ISE project and synthesise from there for review." & exit /b 1)
%XILINX_BIN_PATH%\nt\bitgen -intstyle ise -f zxuno_2Mb_Ext_top.ut zxuno_2Mb_Ext_top.ncd
if errorlevel 1 ("Error running bitgen, open the ISE project and synthesise from there for review." & exit /b 1)
Bit2Bin.exe zxuno_2Mb_Ext_top.bit coreXX.zx1
if errorlevel 1 exit /b 1
copy coreXX.zx1 ..\..\..\..\releases\VGA_31KHz\zxuno_2Mb_Ext\ /y
if errorlevel 1 exit /b 1
timeout /t 10 /nobreak >nul
clean