`default_nettype none

module eu_rom(
	input		wire					clk,
	input		wire					clka,
	input		wire	[11:0]		addra,
	output	reg	[31:0]		douta
);

reg [31:0] memory[3961:0];

initial $readmemb("microcode.mem", memory);

always @(posedge clka)
  douta <= memory[addra];

endmodule