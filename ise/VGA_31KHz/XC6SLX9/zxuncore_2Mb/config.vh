// Model

// XC6SLX9 (ZXUno Family)
// `define ZXUNO_512KB 
// `define ZXUNO_2MB
// `define ZXUNO_2MB_EXT
// `define ZXUNCORE_512KB
`define ZXUNCORE_2MB
// `define VGAWIFI

// XC6SLX16 (ZXDos Family)
// `define ZXDOS_512KB
// `define ZXDOS_1MB
// `define NGO

// XC6SLX25 (ZXDos+ Family)
// `define ZXDOSPLUS
// `define UNOXT
// `define UNOXT2

// ROMs

`define BIOS_WRITABLE = 1'b1;   // 0=No, 1=Yes

`define ROM_BIOS "pcxt31.hex" // 8Kb BIOS
`define XTIDE_BIOS "xtide.hex" // Up to 16Kb

// Splash Screen

`define SPLASH_ENABLE
// `define SPLASH_SCR "splash_zxuno_512kb.hex"
// `define SPLASH_SCR "splash_zxuno_2mb.hex"
// `define SPLASH_SCR "splash_zxuncore_512kb.hex"
`define SPLASH_SCR "splash_zxuncore_2mb.hex"

// `define SPLASH_SCR "splash_zxdos_512kb.hex"
// `define SPLASH_SCR "splash_zxdos_1mb.hex"
// `define SPLASH_SCR "splash_ngo.hex"

// `define SPLASH_SCR "splash_unoxt.hex"
// `define SPLASH_SCR "splash_unoxt2.hex"
// `define SPLASH_SCR "splash_zxdosplus.hex"

// Initial Video Output
  localparam
    VIDEO_OPTION = 1'b1;   // 0=RGB, 1=VGA	 
 
// Memory
// `define MEM_512KB
// `define MEM_1MB
`define MEM_2MB
 
// Features
  localparam
    TURBO_MODE = 1'b0;   // 0=Off, 1=On

// `define PHISICAL_BUTTONS
`define SOUND_ADLIB
// `define SOUND_TANDY
