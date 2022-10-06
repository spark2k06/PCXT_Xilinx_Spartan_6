`default_nettype none

module clk_div3(
	input		wire					clk,
	output	reg					clk_out
	);
 
reg [1:0] pos_count = 2'b00; 
reg [1:0] neg_count = 2'b00;
wire [1:0] r_nxt;

always @(posedge clk) begin
	if (pos_count ==2) begin
		pos_count <= 0;
		clk_out <= 1'b1;
	end
	else begin
		pos_count<= pos_count +1;
		clk_out <= 1'b0;
	end
end

endmodule
