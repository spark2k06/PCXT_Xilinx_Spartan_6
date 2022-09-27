module KF8255_Port_C (
	clock,
	reset,
	chip_select_n,
	read_enable_n,
	internal_data_bus,
	write_port_a,
	write_port_b,
	write_port_c_bit_set,
	write_port_c,
	read_port_a,
	read_port_b,
	read_port_c,
	update_group_a_mode,
	update_group_b_mode,
	group_a_mode_reg,
	group_b_mode_reg,
	group_a_port_a_io_reg,
	group_b_port_b_io_reg,
	group_a_port_c_io_reg,
	group_b_port_c_io_reg,
	port_a_strobe,
	port_b_strobe,
	port_a_hiz,
	port_c_io,
	port_c_out,
	port_c_in,
	port_c_read
);
	input wire clock;
	input wire reset;
	input wire chip_select_n;
	input wire read_enable_n;
	input wire [7:0] internal_data_bus;
	input wire write_port_a;
	input wire write_port_b;
	input wire write_port_c_bit_set;
	input wire write_port_c;
	input wire read_port_a;
	input wire read_port_b;
	input wire read_port_c;
	input wire update_group_a_mode;
	input wire update_group_b_mode;
	input wire [1:0] group_a_mode_reg;
	input wire [1:0] group_b_mode_reg;
	input wire group_a_port_a_io_reg;
	input wire group_b_port_b_io_reg;
	input wire group_a_port_c_io_reg;
	input wire group_b_port_c_io_reg;
	output wire port_a_strobe;
	output wire port_b_strobe;
	output wire port_a_hiz;
	output reg [7:0] port_c_io;
	output reg [7:0] port_c_out;
	input wire [7:0] port_c_in;
	output reg [7:0] port_c_read;
	reg read_port_a_ff;
	reg read_port_b_ff;
	wire stb_a_n;
	reg ibf_a;
	reg obf_a_n;
	wire ack_a_n;
	reg intr_a;
	reg intr_a_mode2_read;
	reg intr_a_mode2_write;
	reg intr_a_mode2_read_reg;
	reg intr_a_mode2_write_reg;
	wire inte_a;
	wire inte_1;
	wire inte_2;
	wire stb_b_n;
	reg ibf_b;
	reg obf_b_n;
	wire ack_b_n;
	reg intr_b;
	wire inte_b;
	wire [2:0] update_group_a_mode_reg;
	wire [2:0] update_group_b_mode_reg;
	wire update_group_a_port_a_io_reg;
	wire update_group_b_port_b_io_reg;
	reg [7:0] port_c_read_comb;
	always @(posedge clock or posedge reset)
		if (reset) begin
			read_port_a_ff <= 1'b0;
			read_port_b_ff <= 1'b0;
		end
		else begin
			read_port_a_ff <= read_port_a;
			read_port_b_ff <= read_port_b;
		end
	assign stb_a_n = (port_c_io[4] == 1'b1 ? port_c_in[4] : 1'b1);
	assign port_a_strobe = ~stb_a_n;
	always @(*) begin
		ibf_a = port_c_out[5];
		if (~stb_a_n)
			ibf_a = 1'b1;
		if (read_port_a != read_port_a_ff)
			if (read_port_a == 1'b0)
				ibf_a = 1'b0;
	end
	always @(*) begin
		obf_a_n = port_c_out[7];
		if (write_port_a)
			obf_a_n = 1'b0;
		if (~ack_a_n)
			obf_a_n = 1'b1;
	end
	assign ack_a_n = (port_c_io[6] == 1'b1 ? port_c_in[6] : 1'b1);
	assign port_a_hiz = ack_a_n;
	always @(*) begin
		intr_a = port_c_out[3];
		intr_a_mode2_read = intr_a_mode2_read_reg;
		intr_a_mode2_write = intr_a_mode2_write_reg;
		casez (group_a_mode_reg)
			2'b1z: begin
				if (inte_2) begin
					if (stb_a_n & ibf_a)
						intr_a_mode2_read = 1'b1;
					if (read_port_a != read_port_a_ff)
						if (read_port_a == 1'b1)
							intr_a_mode2_read = 1'b0;
				end
				else
					intr_a_mode2_read = 1'b0;
				if (inte_1) begin
					if (ack_a_n & obf_a_n)
						intr_a_mode2_write = 1'b1;
					if (write_port_a)
						intr_a_mode2_write = 1'b0;
				end
				else
					intr_a_mode2_write = 1'b0;
				intr_a = intr_a_mode2_read | intr_a_mode2_write;
			end
			default: begin
				if (group_a_port_a_io_reg == 1'b1) begin
					if ((stb_a_n & ibf_a) & inte_a)
						intr_a = 1'b1;
					if (read_port_a != read_port_a_ff)
						if (read_port_a == 1'b1)
							intr_a = 1'b0;
				end
				else begin
					if ((ack_a_n & obf_a_n) & inte_a)
						intr_a = 1'b1;
					if (write_port_a)
						intr_a = 1'b0;
				end
				if (~inte_a)
					intr_a = 1'b0;
			end
		endcase
	end
	assign inte_a = (group_a_port_a_io_reg == 1'b1 ? port_c_out[4] : port_c_out[6]);
	assign inte_1 = port_c_out[6];
	assign inte_2 = port_c_out[4];
	assign stb_b_n = (port_c_io[2] == 1'b1 ? port_c_in[2] : 1'b1);
	assign port_b_strobe = ~stb_b_n;
	always @(*) begin
		ibf_b = port_c_out[1];
		if (~stb_b_n)
			ibf_b = 1'b1;
		if (read_port_b != read_port_b_ff)
			if (read_port_b == 1'b0)
				ibf_b = 1'b0;
	end
	always @(*) begin
		obf_b_n = port_c_out[1];
		if (write_port_b)
			obf_b_n = 1'b0;
		if (~ack_b_n)
			obf_b_n = 1'b1;
	end
	assign ack_b_n = (port_c_io[2] == 1'b1 ? port_c_in[2] : 1'b1);
	always @(*) begin
		intr_b = port_c_out[0];
		if (group_b_port_b_io_reg == 1'b1) begin
			if ((stb_b_n & ibf_b) & inte_b)
				intr_b = 1'b1;
			if (read_port_b != read_port_b_ff)
				if (read_port_b == 1'b1)
					intr_b = 1'b0;
		end
		else begin
			if ((ack_b_n & obf_b_n) & inte_b)
				intr_b = 1'b1;
			if (write_port_b)
				intr_b = 1'b0;
		end
		if (~inte_b)
			intr_b = 1'b0;
	end
	assign inte_b = port_c_out[2];
	reg [7:0] port_c_io_comb;
	always @(*) begin
		port_c_io_comb[0] = 1'b1;
		port_c_io_comb[1] = 1'b1;
		port_c_io_comb[2] = 1'b1;
		port_c_io_comb[3] = 1'b1;
		port_c_io_comb[4] = 1'b1;
		port_c_io_comb[5] = 1'b1;
		port_c_io_comb[6] = 1'b1;
		port_c_io_comb[7] = 1'b1;
		casez (group_b_mode_reg)
			2'b00:
				if (group_b_port_c_io_reg == 1'b0) begin
					port_c_io_comb[0] = 1'b0;
					port_c_io_comb[1] = 1'b0;
					port_c_io_comb[2] = 1'b0;
					port_c_io_comb[3] = 1'b0;
				end
			2'b01: begin
				if (group_b_port_b_io_reg == 1'b1) begin
					port_c_io_comb[0] = 1'b0;
					port_c_io_comb[1] = 1'b0;
					port_c_io_comb[2] = 1'b1;
				end
				else begin
					port_c_io_comb[0] = 1'b0;
					port_c_io_comb[1] = 1'b0;
					port_c_io_comb[2] = 1'b1;
				end
				if (group_b_port_c_io_reg == 1'b0)
					port_c_io_comb[3] = 1'b0;
			end
			default:
				;
		endcase
		casez (group_a_mode_reg)
			2'b00:
				if (group_a_port_c_io_reg == 1'b0) begin
					port_c_io_comb[4] = 1'b0;
					port_c_io_comb[5] = 1'b0;
					port_c_io_comb[6] = 1'b0;
					port_c_io_comb[7] = 1'b0;
				end
			2'b01:
				if (group_a_port_a_io_reg == 1'b1) begin
					port_c_io_comb[3] = 1'b0;
					port_c_io_comb[4] = 1'b1;
					port_c_io_comb[5] = 1'b0;
					if (group_a_port_c_io_reg == 1'b0) begin
						port_c_io_comb[6] = 1'b0;
						port_c_io_comb[7] = 1'b0;
					end
				end
				else begin
					port_c_io_comb[3] = 1'b0;
					port_c_io_comb[6] = 1'b1;
					port_c_io_comb[7] = 1'b0;
					if (group_a_port_c_io_reg == 1'b0) begin
						port_c_io_comb[4] = 1'b0;
						port_c_io_comb[5] = 1'b0;
					end
				end
			2'b1z: begin
				port_c_io_comb[3] = 1'b0;
				port_c_io_comb[4] = 1'b1;
				port_c_io_comb[5] = 1'b0;
				port_c_io_comb[6] = 1'b1;
				port_c_io_comb[7] = 1'b0;
			end
			default:
				;
		endcase
	end
	always @(posedge clock or posedge reset)
		if (reset) begin
			port_c_io[0] <= 1'b1;
			port_c_io[1] <= 1'b1;
			port_c_io[2] <= 1'b1;
			port_c_io[3] <= 1'b1;
			port_c_io[4] <= 1'b1;
			port_c_io[5] <= 1'b1;
			port_c_io[6] <= 1'b1;
			port_c_io[7] <= 1'b1;
		end
		else
			port_c_io <= port_c_io_comb;
	assign update_group_a_mode_reg = internal_data_bus[6:5];
	assign update_group_b_mode_reg = {1'b0, internal_data_bus[2]};
	assign update_group_a_port_a_io_reg = internal_data_bus[4];
	assign update_group_b_port_b_io_reg = internal_data_bus[1];
	always @(posedge clock or posedge reset)
		if (reset)
			port_c_out[0] <= 1'b0;
		else if (write_port_c_bit_set && (internal_data_bus[3:1] == 3'b000))
			port_c_out[0] <= internal_data_bus[0];
		else if (write_port_c)
			port_c_out[0] <= internal_data_bus[0];
		else if (update_group_b_mode)
			port_c_out[0] <= 1'b0;
		else
			casez (group_b_mode_reg)
				2'b00: port_c_out[0] <= port_c_out[0];
				2'b01: port_c_out[0] <= intr_b;
				default: port_c_out[0] <= port_c_out[0];
			endcase
	always @(posedge clock or posedge reset)
		if (reset)
			port_c_out[1] <= 1'b0;
		else if (write_port_c_bit_set && (internal_data_bus[3:1] == 3'b001))
			port_c_out[1] <= internal_data_bus[0];
		else if (write_port_c)
			port_c_out[1] <= internal_data_bus[1];
		else if (update_group_b_mode)
			casez (update_group_b_mode_reg)
				2'b00: port_c_out[1] <= 1'b0;
				2'b01: port_c_out[1] <= (update_group_b_port_b_io_reg == 1'b1 ? 1'b0 : 1'b1);
				default: port_c_out[1] <= 1'b0;
			endcase
		else
			casez (group_b_mode_reg)
				2'b00: port_c_out[1] <= port_c_out[1];
				2'b01: port_c_out[1] <= (group_b_port_b_io_reg == 1'b1 ? ibf_b : obf_b_n);
				default: port_c_out[1] <= 1'b0;
			endcase
	always @(posedge clock or posedge reset)
		if (reset)
			port_c_out[2] <= 1'b0;
		else if (write_port_c_bit_set && (internal_data_bus[3:1] == 3'b010))
			port_c_out[2] <= internal_data_bus[0];
		else if (write_port_c)
			port_c_out[2] <= internal_data_bus[2];
		else if (update_group_b_mode)
			port_c_out[2] <= 1'b0;
		else
			port_c_out[2] <= port_c_out[2];
	always @(posedge clock or posedge reset)
		if (reset)
			port_c_out[3] <= 1'b0;
		else if (write_port_c_bit_set && (internal_data_bus[3:1] == 3'b011))
			port_c_out[3] <= internal_data_bus[0];
		else if (write_port_c)
			port_c_out[3] <= internal_data_bus[3];
		else if (update_group_a_mode)
			port_c_out[3] <= 1'b0;
		else
			casez (group_a_mode_reg)
				2'b00: port_c_out[3] <= port_c_out[3];
				2'b01: port_c_out[3] <= intr_a;
				2'b1z: port_c_out[3] <= intr_a;
				default: port_c_out[3] <= port_c_out[3];
			endcase
	always @(posedge clock or posedge reset)
		if (reset) begin
			intr_a_mode2_read_reg <= 1'b0;
			intr_a_mode2_write_reg <= 1'b0;
		end
		else begin
			intr_a_mode2_read_reg <= intr_a_mode2_read;
			intr_a_mode2_write_reg <= intr_a_mode2_write;
		end
	always @(posedge clock or posedge reset)
		if (reset)
			port_c_out[4] <= 1'b0;
		else if (write_port_c_bit_set && (internal_data_bus[3:1] == 3'b100))
			port_c_out[4] <= internal_data_bus[0];
		else if (write_port_c)
			port_c_out[4] <= internal_data_bus[4];
		else if (update_group_a_mode)
			port_c_out[4] <= 1'b0;
		else
			port_c_out[4] <= port_c_out[4];
	always @(posedge clock or posedge reset)
		if (reset)
			port_c_out[5] <= 1'b0;
		else if (write_port_c_bit_set && (internal_data_bus[3:1] == 3'b101))
			port_c_out[5] <= internal_data_bus[0];
		else if (write_port_c)
			port_c_out[5] <= internal_data_bus[5];
		else if (update_group_a_mode)
			port_c_out[5] <= 1'b0;
		else
			casez (group_a_mode_reg)
				2'b00: port_c_out[5] <= port_c_out[5];
				2'b01: port_c_out[5] <= (group_a_port_a_io_reg == 1'b1 ? ibf_a : port_c_out[5]);
				2'b1z: port_c_out[5] <= ibf_a;
				default: port_c_out[5] <= port_c_out[5];
			endcase
	always @(posedge clock or posedge reset)
		if (reset)
			port_c_out[6] <= 1'b0;
		else if (write_port_c_bit_set && (internal_data_bus[3:1] == 3'b110))
			port_c_out[6] <= internal_data_bus[0];
		else if (write_port_c)
			port_c_out[6] <= internal_data_bus[6];
		else if (update_group_a_mode)
			port_c_out[6] <= 1'b0;
		else
			port_c_out[6] <= port_c_out[6];
	always @(posedge clock or posedge reset)
		if (reset)
			port_c_out[7] <= 1'b0;
		else if (write_port_c_bit_set && (internal_data_bus[3:1] == 3'b111))
			port_c_out[7] <= internal_data_bus[0];
		else if (write_port_c)
			port_c_out[7] <= internal_data_bus[7];
		else if (update_group_a_mode)
			casez (update_group_a_mode_reg)
				2'b00: port_c_out[7] <= 1'b0;
				2'b01: port_c_out[7] <= (update_group_a_port_a_io_reg == 1'b1 ? 1'b0 : 1'b1);
				2'b1z: port_c_out[7] <= 1'b1;
				default: port_c_out[7] <= 1'b0;
			endcase
		else
			casez (group_a_mode_reg)
				2'b00: port_c_out[7] <= port_c_out[7];
				2'b01: port_c_out[7] <= (group_a_port_a_io_reg == 1'b1 ? port_c_out[7] : obf_a_n);
				2'b1z: port_c_out[7] <= obf_a_n;
				default: port_c_out[7] <= port_c_out[7];
			endcase
	always @(*) begin
		port_c_read_comb = port_c_in;
		if (port_c_io[0] == 1'b0)
			port_c_read_comb[0] = port_c_out[0];
		if (port_c_io[1] == 1'b0)
			port_c_read_comb[1] = port_c_out[1];
		if (port_c_io[2] == 1'b0)
			port_c_read_comb[2] = port_c_out[2];
		if (port_c_io[3] == 1'b0)
			port_c_read_comb[3] = port_c_out[3];
		if (port_c_io[4] == 1'b0)
			port_c_read_comb[4] = port_c_out[4];
		if (port_c_io[5] == 1'b0)
			port_c_read_comb[5] = port_c_out[5];
		if (port_c_io[6] == 1'b0)
			port_c_read_comb[6] = port_c_out[6];
		if (port_c_io[7] == 1'b0)
			port_c_read_comb[7] = port_c_out[7];
	end
	always @(posedge clock or posedge reset)
		if (reset)
			port_c_read <= 8'b00000000;
		else if (update_group_a_mode & update_group_b_mode)
			port_c_read <= 8'b00000000;
		else if (update_group_a_mode)
			port_c_read <= {4'b0000, port_c_read_comb[3:0]};
		else if (update_group_b_mode)
			port_c_read <= {port_c_read_comb[7:4], 4'b0000};
		else
			port_c_read <= port_c_read_comb;
endmodule
