// ZXUno model

`define ZXUNO_512KB
// `define ZXUNO_2MB
// `define ZXUNCORE_512KB
// `define ZXUNCORE_2MB
// `define UNOXT
// `define UNOXT2

// ROMs

`define BIOS_WRITABLE = 1'b1;   // 0=No, 1=Yes

`define ROM_BIOS "pcxt31.hex" // 8Kb BIOS
`define XTIDE_BIOS "xtide.hex" // Up to 16Kb

// Splash Screen

`define SPLASH_ENABLE

`define SPLASH_SCR_ZXUNO_2MB "splash_zxuno_2mb.hex"
`define SPLASH_SCR_ZXUNO_512KB "splash_zxuno_512kb.hex"
`define SPLASH_SCR_ZXUNCORE_2MB "splash_zxuncore_2mb.hex"
`define SPLASH_SCR_ZXUNCORE_512KB "splash_zxuncore_512kb.hex"
`define SPLASH_SCR_UNOXT "splash_unoxt.hex"
`define SPLASH_SCR_UNOXT2 "splash_unoxt2.hex"

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
`endif

`ifdef ZXUNCORE_512KB
	`define MEM_512KB
`endif

`ifdef ZXUNO_2MB
	`define MEM_2MB
`endif

`ifdef ZXUNCORE_2MB
	`define MEM_2MB
`endif

`ifdef UNOXT
	`define MEM_4MB
	`define PHISICAL_BUTTONS
`endif

`ifdef UNOXT2
	`define MEM_4MB
	`define PHISICAL_BUTTONS
`endif


    
