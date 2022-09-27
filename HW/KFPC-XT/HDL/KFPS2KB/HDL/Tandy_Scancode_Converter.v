module Tandy_Scancode_Converter (
	clock,
	reset,
	scancode,
	keybord_irq,
	convert_data
);
	input wire clock;
	input wire reset;
	input wire [7:0] scancode;
	input wire keybord_irq;
	output wire [7:0] convert_data;
	reg e0_temp;
	reg e0;
	reg prev_keybord_irq;
	wire keybord_irq_posedge;
	wire keybord_irq_negedge;
	function [6:0] tandy_code_converter;
		input [6:0] code;
		input e0_flag;
		casez ({e0_flag, code})
			8'b11001000: tandy_code_converter = 7'h29;
			8'b11001011: tandy_code_converter = 7'h2b;
			8'b11010000: tandy_code_converter = 7'h4a;
			8'b11001101: tandy_code_converter = 7'h4e;
			8'b01001010: tandy_code_converter = 7'h53;
			8'b01001110: tandy_code_converter = 7'h55;
			8'b01010011: tandy_code_converter = 7'h56;
			8'b10011100: tandy_code_converter = 7'h57;
			8'b11000111: tandy_code_converter = 7'h58;
			8'bz1010111: tandy_code_converter = 7'h59;
			8'bz1011000: tandy_code_converter = 7'h5a;
			default: tandy_code_converter = code;
		endcase
	endfunction
	always @(posedge clock or posedge reset)
		if (reset)
			prev_keybord_irq <= 1'b0;
		else
			prev_keybord_irq <= keybord_irq;
	assign keybord_irq_posedge = ~prev_keybord_irq & keybord_irq;
	assign keybord_irq_negedge = prev_keybord_irq & ~keybord_irq;
	always @(posedge clock or posedge reset)
		if (reset) begin
			e0 <= 1'b0;
			e0_temp <= 1'b0;
		end
		else if (keybord_irq_posedge) begin
			e0 <= e0;
			if (scancode == 8'he0)
				e0_temp <= 1'b1;
			else
				e0_temp <= 1'b0;
		end
		else if (keybord_irq_negedge) begin
			e0 <= e0_temp;
			e0_temp <= 1'b0;
		end
		else begin
			e0 <= e0;
			e0_temp <= e0_temp;
		end
	assign convert_data = {scancode[7], tandy_code_converter(scancode[6:0], e0)};
endmodule
