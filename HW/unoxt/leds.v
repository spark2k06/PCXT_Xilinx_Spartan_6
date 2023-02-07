`timescale 1ns / 1ps
`default_nettype wire
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: emax73
// 
// Create Date:    09:24:18 10/23/2021 
// Design Name: 
// Module Name:    leds 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: LEDs PWM Driver
//
// Dependencies: 
//
// Revision: 
// Revision 0.8 - File Created
// Additional Comments: 
// License: GPLv3
//
//////////////////////////////////////////////////////////////////////////////////
module ledPWM(
		input nReset,
		input clock,
		input enable, // Off/On
		input[15:0] y1, // 0-100% brightness1
		input[15:0] y2, // 0-100% brightness2
		output led // LED output
    );
	 
	 reg[15:0] cnt;
	 wire[15:0] pwm;
	 localparam period = 16'd10000;

	 assign pwm = (enable) ? (y1 * y2) : 16'd0;

	always @(posedge clock)
	begin
		if (!nReset)
				cnt <= 16'd0;
		else
		begin
			if (cnt < period - 16'd1)
				cnt <= cnt + 16'd1;
			else
				cnt <= 16'd0;
		end
	end
	
	reg ledO;
	always @(posedge clock)
	begin
		if (cnt < pwm)
			ledO <= 1'b1;
		else
			ledO <= 1'b0;
	end
	
	assign led = ledO;
	
endmodule

module flashCnt(
	input clk,
	input signal,
	input [31:0] msec,
	output flash
);
	parameter CLK_MHZ = 16'd21;

	wire [31:0] duration;
	assign duration = CLK_MHZ * msec * 16'd1000;
	
	reg signal0 = 1'b0;
	always @(posedge clk)
	begin
		signal0 <= signal;
	end;
	reg [31:0] cnt;
	assign counting = (cnt < duration);
	always @(posedge clk)
	begin
		if (signal != signal0)
			cnt <= 32'h00;
		else if (counting)
			cnt <= cnt + 32'd1;	
	end;
	assign flash = counting;

endmodule
