module rom #(parameter AW=16, parameter filename="")
(
  input wire clka,
  input wire ena,
  input wire wea,
  input wire [AW-1:0] addra,
  input wire [7:0] dina,
  output reg [7:0] douta
);

reg [7:0] rom[(2**AW)-1:0];

initial $readmemh(filename, rom);

always @(posedge clka)
  if (ena)
		if (wea)
			rom[addra] <= dina;
		else
			douta <= rom[addra];

endmodule