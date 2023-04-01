// Model

// XC6SLX9
`define ZXUNO_512KB 
// `define ZXUNO_2MB
// `define ZXUNO_2MB_EXT
// `define ZXUNCORE_512KB
// `define ZXUNCORE_2MB

// XC6SLX16
// `define ZXDOS_512KB
// `define ZXDOS_1MB

// XC6SLX25
// `define UNOXT
// `define UNOXT2

// ROMs

`define BIOS_WRITABLE = 1'b1;   // 0=No, 1=Yes

`define ROM_BIOS "pcxt31.hex" // 8Kb BIOS
`define XTIDE_BIOS "xtide.hex" // Up to 16Kb

// Splash Screen

`define SPLASH_ENABLE

// Initial Video Output
  localparam
    VIDEO_OPTION = 1'b0;   // 0=RGB, 1=VGA	 
 
// Features
  localparam
    TURBO_MODE = 1'b0;   // 0=Off, 1=On

// `define SOUND_ADLIB
// `define SOUND_TANDY

// Automatic defines

`ifdef ZXUNO_512KB
	`define MEM_512KB
	`define SPLASH_SCR "splash_zxuno_512kb.hex"
`endif

`ifdef ZXUNCORE_512KB
	`define SPLASH_SCR "splash_zxuncore_512kb.hex"
	`define MEM_512KB
`endif

`ifdef ZXUNO_2MB
	`define MEM_2MB
	`define SPLASH_SCR "splash_zxuno_2mb.hex"
`endif

`ifdef ZXUNO_2MB_EXT
	`define MEM_2MB
	`define SPLASH_SCR "splash_zxuno_2mb_ext.hex"
`endif

`ifdef ZXDOS_512KB
	`define MEM_512KB
	`define SPLASH_SCR "splash_zxdos_512kb.hex"
`endif

`ifdef ZXUNCORE_2MB
	`define MEM_2MB
	`define SPLASH_SCR "splash_zxuncore_2mb.hex"
`endif

`ifdef UNOXT
	`define MEM_4MB
	`define SPLASH_SCR "splash_unoxt.hex"
	`define PHISICAL_BUTTONS
`endif

`ifdef UNOXT2
	`define MEM_4MB
	`define SPLASH_SCR "splash_unoxt2.hex"
	`define PHISICAL_BUTTONS
`endif


    
