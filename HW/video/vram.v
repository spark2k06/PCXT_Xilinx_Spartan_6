module splash
(
  input clka,
  input ena,  
  input wea,
  input [11:0] addra,
  input [7:0] dina,
  output reg [7:0] douta
);

reg [7:0] vram[4095:0];

initial $readmemh("splash.hex", vram);

always @(posedge clka)
  if (ena)
		if (wea)
			vram[addra] <= dina;
		else
			douta <= vram[addra];
		
endmodule