`timescale 1ns / 1ps
`default_nettype none

module ZXUno_PCXT_512KB(
	input		wire					CLK_50MHZ,
	output	wire	[2:0]			VGA_R,
	output	wire	[2:0]			VGA_G,
	output	wire	[2:0]			VGA_B,
	output	wire					VGA_HSYNC,
	output	wire					VGA_VSYNC,
	output	wire					SRAM_WE_n,
	output	wire	[18:0]		SRAM_A,
	inout		wire	[7:0]			SRAM_D,

	output	wire					uart_rx,
	input		wire					uart_tx,

	inout		wire					clkps2,
	inout		wire					dataps2,

	output	wire					AUDIO_L,
	output	wire					AUDIO_R
	/*
	output	wire					LED,
	inout		wire					PS2CLKA,
	inout		wire					PS2CLKB,
	inout		wire					PS2DATA,
	inout		wire					PS2DATB,
	output	wire					SD_nCS,
	output	wire					SD_DI,
	output	wire					SD_CK,
	input		wire					SD_DO,
	input		wire					P_A,
	input		wire					P_U,
	input		wire					P_D,
	input		wire					P_L,
	input		wire					P_R,
	input		wire					P_tr
	*/
	);
	
	wire clk_100;
	wire clk_50;
	wire clk_28_571;	
	wire clk_14_815;
	wire clk_3_571;
	
	wire [5:0] R;
	wire [5:0] G;
	wire [5:0] B;
	
	assign VGA_R = R[5:3];
	assign VGA_G = G[5:3];
	assign VGA_B = B[5:3];
	
	dcm dcm_system 
	(
		.CLK_IN1(CLK_50MHZ), 
		.CLK_OUT1(clk_100),
		.CLK_OUT2(clk_50),
		.CLK_OUT3(clk_28_571),
		.CLK_OUT4(clk_14_815),
		.CLK_OUT5(clk_3_571)
    );
   
	system_512KB sys_inst
	(	
		.clk_100(clk_100),
		.clk_chipset(clk_50),
		.clk_vga(clk_28_571),
		.clk_uart(clk_14_815),
		.clk_opl2(clk_3_571),		
		
		.VGA_R(R),
		.VGA_G(G),
		.VGA_B(B),
		.VGA_HSYNC(VGA_HSYNC),
		.VGA_VSYNC(VGA_VSYNC),
		.SRAM_ADDR(SRAM_A),
		.SRAM_DATA(SRAM_D),
		.SRAM_WE_n(SRAM_WE_n),
		.uart_rx(uart_tx),
		.uart_tx(uart_rx),
//		.LED(LED),
		.clkps2(clkps2),
		.dataps2(dataps2),
		.AUD_L(AUDIO_L),
		.AUD_R(AUDIO_R)
//	 	.PS2_CLK1(PS2CLKA),
//		.PS2_CLK2(PS2CLKB),
//		.PS2_DATA1(PS2DATA),
//		.PS2_DATA2(PS2DATB)

//		.SD_n_CS(SD_nCS),
//		.SD_DI(SD_DI),
//		.SD_CK(SD_CK),
//		.SD_DO(SD_DO),
//		.joy_up(P_U),
//		.joy_down(P_D),
//		.joy_left(P_L),
//		.joy_right(P_R),
//		.joy_fire1(P_tr),
//		.joy_fire2(P_A)
		
	);

endmodule
