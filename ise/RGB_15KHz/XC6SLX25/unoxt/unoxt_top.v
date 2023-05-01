`timescale 1ns / 1ns
`default_nettype wire

//    This file is part of the UnoXT Dev Board Project. 
//    (copyleft)2022 emax73.
//    UnoXT official repository: https://gitlab.com/emax73g/unoxt-hardware
//
//    UnoXT core is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    UnoXT core is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with the UnoXT core.  If not, see <https://www.gnu.org/licenses/>.
//
//    Any distributed copy of this file must keep this notice intact.

	module unoxt_top (

   input wire clock_50_i,
	
   output wire [4:0] rgb_r_o,
   output wire [4:0] rgb_g_o,
   output wire [4:0] rgb_b_o,
   output wire hsync_o,
   output wire vsync_o,
   input wire ear_port_i,
   output wire mic_port_o,
   inout wire ps2_clk_io,
   inout wire ps2_data_io,
   inout wire ps2_pin6_io,
   inout wire ps2_pin2_io,
   output wire audioext_l_o,
   output wire audioext_r_o,

   inout wire esp_gpio0_io,
   inout wire esp_gpio2_io,
   output wire esp_tx_o,
   input wire esp_rx_i,
 
   output wire [20:0] ram_addr_o,
   output wire ram_lb_n_o,
   output wire ram_ub_n_o,
   inout wire [15:0] ram_data_io,
   output wire ram_oe_n_o,
   output wire ram_we_n_o,
   output wire ram_ce_n_o,
   
   output wire flash_cs_n_o,
   output wire flash_sclk_o,
   output wire flash_mosi_o,
   input wire flash_miso_i,
   output wire flash_wp_o,
   output wire flash_hold_o,
/*	
   input wire joyp1_i,
   input wire joyp2_i,
   input wire joyp3_i,
   input wire joyp4_i,
   input wire joyp6_i,
   output wire joyp7_o,
   input wire joyp9_i,
*/
	
   input wire btn_green_n_i,
   input wire btn_yellow_n_i,

   output wire sd_cs0_n,    
   output wire sd_sclk,   // CLK
   output wire sd_mosi,   // CMD
   input  wire sd_miso,   // DAT0

   output wire led_red_o,
   output wire led_yellow_o,
   output wire led_green_o,
   output wire led_blue_o,

	inout wire [8:0] test

   );

	wire [4:0] joy1;
	
	wire clk_100;
	wire clk_50;
	wire clk_28_571;	
	wire clk_14_815;
	wire clk_3_571;
	
	wire [5:0] R;
	wire [5:0] G;
	wire [5:0] B;
	
	assign rgb_r_o = R[5:1];
	assign rgb_g_o = G[5:1];
	assign rgb_b_o = B[5:1];
	
	dcm dcm_system 
	(
		.CLK_IN1(clock_50_i), 
		.CLK_OUT1(clk_100),
		.CLK_OUT2(clk_50),
		.CLK_OUT3(clk_28_571),
		.CLK_OUT4(clk_3_571)
   );
   
	system sys_inst
	(
		.clk_100(clk_100),
		.clk_chipset(clk_50),
		.clk_vga(clk_28_571),
		.clk_opl2(clk_3_571),
		
		.turbo(led_yellow_o),
		
		.VGA_R(R),
		.VGA_G(G),
		.VGA_B(B),
		.VGA_HSYNC(hsync_o),
		.VGA_VSYNC(vsync_o),
		.SRAM_ADDR(ram_addr_o),
		.SRAM_DATA(ram_data_io[7:0]),
		.SRAM_WE_n(ram_we_n_o),
//		.LED(LED),
		.clkps2(ps2_clk_io),
		.dataps2(ps2_data_io),
		.AUD_L(audioext_l_o),
		.AUD_R(audioext_r_o),
//	 	.PS2_CLK1(PS2CLKA),
//		.PS2_CLK2(PS2CLKB),
//		.PS2_DATA1(PS2DATA),
//		.PS2_DATA2(PS2DATB)

		.SD_nCS(sd_cs0_n),
		.SD_DI(sd_mosi),
		.SD_CK(sd_sclk),
		.SD_DO(sd_miso),
		.btn_green_n_i(btn_green_n_i),
		.btn_yellow_n_i(btn_yellow_n_i)

//		.joy_up(P_U),
//		.joy_down(P_D),
//		.joy_left(P_L),
//		.joy_right(P_R),
//		.joy_fire1(P_tr),
//		.joy_fire2(P_A)
		
	);

// assign joyp7_o = 1'b1;
//	assign joy1 = {joyp6_i, joyp1_i, joyp2_i, joyp3_i, joyp4_i};
	
	assign ram_oe_n_o = 1'b0;
	assign ram_ce_n_o = 1'b0;
	assign ram_lb_n_o = 1'b0;
	assign ram_ub_n_o = 1'b1;
	assign ram_data_io[15:8] = 8'bz;
	
	assign mic_port_o = 1'b1;
 
	assign esp_gpio0_io = 1'b1;
	assign esp_gpio2_io = 1'b1;
	assign esp_tx_o = 1'b1;
	
	assign flash_cs_n_o = 1'b1;
	assign flash_sclk_o = 1'b1;
	assign flash_mosi_o = 1'b1;
	assign flash_wp_o = 1'b1;
	assign flash_hold_o = 1'b1;

	assign led_red_o = 1'b1;
	assign led_blue_o = 1'b0;
	assign led_green_o = ~sd_miso;
	
	/*
	flashCnt #(.CLK_MHZ(16'd50)) cnt(
		.clk(sysclk),
		.signal(uart_rx),
		.msec(16'd20),
		.flash(led_green_o)
	);
	*/
	
//	assign test[0] = uart_tx;
//	assign uart_rx = test[1];
	
	assign test[2] = 1'b1;
	assign test[3] = 1'b1;
	assign test[4] = 1'b1;
	assign test[5] = 1'b1;
	assign test[6] = 1'b1;
	assign test[7] = 1'b1;
	assign test[8] = 1'b1;
  
endmodule
