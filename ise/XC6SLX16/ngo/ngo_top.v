`timescale 1ns / 1ns
`default_nettype wire

module ngo_top(
	input		wire					CLK_50MHZ,
	output	wire	[2:0]			VGA_R,
	output	wire	[2:0]			VGA_G,
	output	wire	[2:0]			VGA_B,
	output	wire					VGA_HSYNC,
	output	wire					VGA_VSYNC,
	output	wire	[18:0]		SRAM_A,
	inout		wire	[15:0]		SRAM_D,	
	output	wire					SRAM_WE_n,
	
	output	wire 					SRAM_OE_n,
	output	wire 					SRAM_CE_n_o0,
	output	wire 					SRAM_CE_n_o1,
	output	wire 					SRAM_CE_n_o2,
	output	wire 					SRAM_CE_n_o3,
	
	inout		wire					clkps2,
	inout		wire					dataps2,
	inout		wire					mouseclk,
	inout		wire					mousedata,

	output	wire					AUDIO_L,
	output	wire					AUDIO_R,
	output 	wire					SD_nCS,
	output	wire					SD_DI,
	output	wire					SD_CK,
	input		wire					SD_DO,

	output	wire					LED
	/*
	inout		wire					PS2CLKA,
	inout		wire					PS2CLKB,
	inout		wire					PS2DATA,
	inout		wire					PS2DATB,
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
	
	wire [5:0] R;
	wire [5:0] G;
	wire [5:0] B;

	wire [20:0] RAM_A;
	wire [7:0] RAM_D;
	assign SRAM_A = RAM_A[18:0];
	assign SRAM_D[15:8] = (RAM_A[20:19] == 2'b01 || RAM_A[20:19] == 2'b11) ? RAM_D : 8'hZZ;
	assign SRAM_D[7:0] = (RAM_A[20:19] == 2'b00 || RAM_A[20:19] == 2'b10) ? RAM_D : 8'hZZ;
	assign SRAM_CE_n_o0 = (RAM_A[20:19] == 2'b00) ? 1'b0 : 1'b1;
	assign SRAM_CE_n_o1 = (RAM_A[20:19] == 2'b01) ? 1'b0 : 1'b1;
	assign SRAM_CE_n_o2 = (RAM_A[20:19] == 2'b10) ? 1'b0 : 1'b1;
	assign SRAM_CE_n_o3 = (RAM_A[20:19] == 2'b11) ? 1'b0 : 1'b1;
	assign SRAM_OE_n = 1'b0;
	
	assign VGA_R = R[5:3];
	assign VGA_G = G[5:3];
	assign VGA_B = B[5:3];
	
	dcm dcm_system 
	(
		.CLK_IN1(CLK_50MHZ), 
		.CLK_OUT1(clk_100),
		.CLK_OUT2(clk_50),
		.CLK_OUT3(clk_28_571)
    );
	 

   
	system sys_inst
	(	
		.clk_100(clk_100),
		.clk_chipset(clk_50),
		.clk_vga(clk_28_571),
		
		.VGA_R(R),
		.VGA_G(G),
		.VGA_B(B),
		.VGA_HSYNC(VGA_HSYNC),
		.VGA_VSYNC(VGA_VSYNC),
		.SRAM_ADDR(RAM_A),
		.SRAM_DATA(RAM_D),
		.SRAM_WE_n(SRAM_WE_n),
//		.LED(LED),
		.clkps2(clkps2),
		.dataps2(dataps2),
		.mouseclk(mouseclk),
		.mousedata(mousedata),
		.AUD_L(AUDIO_L),
		.AUD_R(AUDIO_R),
//	 	.PS2_CLK1(PS2CLKA),
//		.PS2_CLK2(PS2CLKB),
//		.PS2_DATA1(PS2DATA),
//		.PS2_DATA2(PS2DATB)

		.SD_nCS(SD_nCS),
		.SD_DI(SD_DI),
		.SD_CK(SD_CK),
		.SD_DO(SD_DO)

//		.joy_up(P_U),
//		.joy_down(P_D),
//		.joy_left(P_L),
//		.joy_right(P_R),
//		.joy_fire1(P_tr),
//		.joy_fire2(P_A)
		
	);
	
assign LED = ~SD_DO;

endmodule
