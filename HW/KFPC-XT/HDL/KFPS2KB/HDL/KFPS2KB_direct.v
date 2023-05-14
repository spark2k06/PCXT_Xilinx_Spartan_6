module KFPS2KB_direct (
	input		wire					clock,
	input		wire					peripheral_clock,
	input		wire					reset,
	input		wire					device_clock,
	input		wire					device_data,
	output	reg					irq,
	output	reg	[7:0]			keycode,
	input		wire					clear_keycode,
   output   reg               turbo_mode,
   output   reg               swap_video,
	input    wire              initial_turbo,
	input    wire              initial_video,
	input    wire              reset_keybord
);
	parameter over_time = 16'd1000;
	wire [7:0] register;
	wire recieved_flag;
	wire recieved_error;
	reg error_flag;
	reg break_flag;
	KFPS2KB_Shift_Register #(.over_time(over_time)) u_Shift_Register(
		.clock(clock),
		.peripheral_clock(peripheral_clock),
		.reset(reset),
		.device_clock(device_clock),
		.device_data(device_data),
		.register(register),
		.recieved_flag(recieved_flag),
		.error_flag(recieved_error)
	);
	function [7:0] scancode_converter;
		input [7:0] code;
		casez (code)
			8'h00: scancode_converter = 8'hff;
			8'h01: scancode_converter = 8'h43;
			8'h02: scancode_converter = 8'h41;
			8'h03: scancode_converter = 8'h3f;
			8'h04: scancode_converter = 8'h3d;
			8'h05: scancode_converter = 8'h3b;
			8'h06: scancode_converter = 8'h3c;
			8'h07: scancode_converter = 8'h58;
			8'h08: scancode_converter = 8'h64;
			8'h09: scancode_converter = 8'h44;
			8'h0a: scancode_converter = 8'h42;
			8'h0b: scancode_converter = 8'h40;
			8'h0c: scancode_converter = 8'h3e;
			8'h0d: scancode_converter = 8'h0f;
			8'h0e: scancode_converter = 8'h29;
			8'h0f: scancode_converter = 8'h59;
			8'h10: scancode_converter = 8'h65;
			8'h11: scancode_converter = 8'h38;
			8'h12: scancode_converter = 8'h2a;
			8'h13: scancode_converter = 8'h70;
			8'h14: scancode_converter = 8'h1d;
			8'h15: scancode_converter = 8'h10;
			8'h16: scancode_converter = 8'h02;
			8'h17: scancode_converter = 8'h5a;
			8'h18: scancode_converter = 8'h66;
			8'h19: scancode_converter = 8'h71;
			8'h1a: scancode_converter = 8'h2c;
			8'h1b: scancode_converter = 8'h1f;
			8'h1c: scancode_converter = 8'h1e;
			8'h1d: scancode_converter = 8'h11;
			8'h1e: scancode_converter = 8'h03;
			8'h1f: scancode_converter = 8'h5b;
			8'h20: scancode_converter = 8'h67;
			8'h21: scancode_converter = 8'h2e;
			8'h22: scancode_converter = 8'h2d;
			8'h23: scancode_converter = 8'h20;
			8'h24: scancode_converter = 8'h12;
			8'h25: scancode_converter = 8'h05;
			8'h26: scancode_converter = 8'h04;
			8'h27: scancode_converter = 8'h5c;
			8'h28: scancode_converter = 8'h68;
			8'h29: scancode_converter = 8'h39;
			8'h2a: scancode_converter = 8'h2f;
			8'h2b: scancode_converter = 8'h21;
			8'h2c: scancode_converter = 8'h14;
			8'h2d: scancode_converter = 8'h13;
			8'h2e: scancode_converter = 8'h06;
			8'h2f: scancode_converter = 8'h5d;
			8'h30: scancode_converter = 8'h69;
			8'h31: scancode_converter = 8'h31;
			8'h32: scancode_converter = 8'h30;
			8'h33: scancode_converter = 8'h23;
			8'h34: scancode_converter = 8'h22;
			8'h35: scancode_converter = 8'h15;
			8'h36: scancode_converter = 8'h07;
			8'h37: scancode_converter = 8'h5e;
			8'h38: scancode_converter = 8'h6a;
			8'h39: scancode_converter = 8'h72;
			8'h3a: scancode_converter = 8'h32;
			8'h3b: scancode_converter = 8'h24;
			8'h3c: scancode_converter = 8'h16;
			8'h3d: scancode_converter = 8'h08;
			8'h3e: scancode_converter = 8'h09;
			8'h3f: scancode_converter = 8'h5f;
			8'h40: scancode_converter = 8'h6b;
			8'h41: scancode_converter = 8'h33;
			8'h42: scancode_converter = 8'h25;
			8'h43: scancode_converter = 8'h17;
			8'h44: scancode_converter = 8'h18;
			8'h45: scancode_converter = 8'h0b;
			8'h46: scancode_converter = 8'h0a;
			8'h47: scancode_converter = 8'h60;
			8'h48: scancode_converter = 8'h6c;
			8'h49: scancode_converter = 8'h34;
			8'h4a: scancode_converter = 8'h35;
			8'h4b: scancode_converter = 8'h26;
			8'h4c: scancode_converter = 8'h27;
			8'h4d: scancode_converter = 8'h19;
			8'h4e: scancode_converter = 8'h0c;
			8'h4f: scancode_converter = 8'h61;
			8'h50: scancode_converter = 8'h6d;
			8'h51: scancode_converter = 8'h7d;
			8'h52: scancode_converter = 8'h28;
			8'h53: scancode_converter = 8'h74;
			8'h54: scancode_converter = 8'h1a;
			8'h55: scancode_converter = 8'h0d;
			8'h56: scancode_converter = 8'h62;
			8'h57: scancode_converter = 8'h6e;
			8'h58: scancode_converter = 8'h3a;
			8'h59: scancode_converter = 8'h36;
			8'h5a: scancode_converter = 8'h1c;
			8'h5b: scancode_converter = 8'h1b;
			8'h5c: scancode_converter = 8'h75;
			8'h5d: scancode_converter = 8'h2b;
			8'h5e: scancode_converter = 8'h63;
			8'h5f: scancode_converter = 8'h76;
			8'h60: scancode_converter = 8'h55;
			8'h61: scancode_converter = 8'h56;
			8'h62: scancode_converter = 8'h77;
			8'h63: scancode_converter = 8'h78;
			8'h64: scancode_converter = 8'h79;
			8'h65: scancode_converter = 8'h7a;
			8'h66: scancode_converter = 8'h0e;
			8'h67: scancode_converter = 8'h7b;
			8'h68: scancode_converter = 8'h7c;
			8'h69: scancode_converter = 8'h4f;
			8'h6a: scancode_converter = 8'h7d;
			8'h6b: scancode_converter = 8'h4b;
			8'h6c: scancode_converter = 8'h47;
			8'h6d: scancode_converter = 8'h7e;
			8'h6e: scancode_converter = 8'h7f;
			8'h6f: scancode_converter = 8'h6f;
			8'h70: scancode_converter = 8'h52;
			8'h71: scancode_converter = 8'h53;
			8'h72: scancode_converter = 8'h50;
			8'h73: scancode_converter = 8'h4c;
			8'h74: scancode_converter = 8'h4d;
			8'h75: scancode_converter = 8'h48;
			8'h76: scancode_converter = 8'h01;
			8'h77: scancode_converter = 8'h45;
			8'h78: scancode_converter = 8'h57;
			8'h79: scancode_converter = 8'h4e;
			8'h7a: scancode_converter = 8'h51;
			8'h7b: scancode_converter = 8'h4a;
			8'h7c: scancode_converter = 8'h37;
			8'h7d: scancode_converter = 8'h49;
			8'h7e: scancode_converter = 8'h46;
			8'h7f: scancode_converter = 8'h54;
			8'h80: scancode_converter = 8'h81;
			8'h81: scancode_converter = 8'h82;
			8'h82: scancode_converter = 8'h83;
			8'h83: scancode_converter = 8'h41;
			8'h84: scancode_converter = 8'h84;
			8'h85: scancode_converter = 8'h85;
			8'h86: scancode_converter = 8'h86;
			8'h87: scancode_converter = 8'h87;
			8'h88: scancode_converter = 8'h88;
			8'h89: scancode_converter = 8'h89;
			8'h8a: scancode_converter = 8'h8a;
			8'h8b: scancode_converter = 8'h8b;
			8'h8c: scancode_converter = 8'h8c;
			8'h8d: scancode_converter = 8'h8d;
			8'h8e: scancode_converter = 8'h8e;
			8'h8f: scancode_converter = 8'h8f;
			default: scancode_converter = code;
		endcase
	endfunction
	always @(posedge clock or posedge reset)
		if (reset) begin
			swap_video <= initial_video;
			turbo_mode <= initial_turbo;
			irq <= 1'b0;
			keycode <= 8'h00;
			break_flag <= 1'b0;			
			error_flag <= 1'b0;
		end
		else if (reset_keybord) begin
			irq <= 1'b1;
			keycode <= 8'haa;
			break_flag <= 1'b0;
		end
		else if (clear_keycode) begin
			irq <= 1'b0;
			keycode <= 8'h00;
			break_flag <= 1'b0;
			error_flag <= 1'b0;
		end
		else if (recieved_error) begin
			irq <= 1'b0;
			keycode <= 8'hff;
			break_flag <= 1'b0;
			error_flag <= 1'b1;
		end
		else if (recieved_flag) begin
			if ((irq == 1'b1) || (error_flag == 1'b1)) begin
				irq <= 1'b0;
				keycode <= 8'hff;
				break_flag <= 1'b0;
				error_flag <= 1'b1;
			end
			else if (register == 8'hfa) begin
				irq <= 1'b0;
				keycode <= 8'h00;
				break_flag <= 1'b0;
				error_flag <= 1'b0;
			end
			else if (register == 8'hf0) begin
				irq <= 1'b0;
				keycode <= 8'h00;
				break_flag <= 1'b1;
				error_flag <= 1'b0;
			end
         else if (register == 8'h78) begin
             // F11: RGB <-> Composite
             irq         <= 1'b0;
             keycode     <= 8'h00;
             break_flag  <= 1'b0;
             swap_video <= break_flag ? ~swap_video : swap_video;
         end
         else if (register == 8'h07) begin
             // F12: Turbo mode ON <-> OFF
             irq         <= 1'b0;
             keycode     <= 8'h00;
             break_flag  <= 1'b0;
             turbo_mode  <= break_flag ? ~turbo_mode : turbo_mode;
         end
			else if (register == 8'h07) begin
				irq <= 1'b0;
				keycode <= 8'h00;
				break_flag <= 1'b0;
			end
			else begin
				irq <= 1'b1;
				keycode <= scancode_converter(register) | (break_flag ? 8'h80 : 8'h00);
				break_flag <= 1'b0;
				error_flag <= 1'b0;
			end
		end
		else begin
			irq <= irq | error_flag;
			keycode <= keycode;
			break_flag <= break_flag;
			error_flag <= error_flag;
		end
endmodule
