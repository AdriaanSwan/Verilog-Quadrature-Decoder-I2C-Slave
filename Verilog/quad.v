module quad(clk, quadA, quadB, count, CMD, TEND);
//Modified from http://www.fpga4fun.com/QuadratureDecoder.html

input clk;
input quadA;
input quadB;
output [15:0] count;
input[7:0] CMD;
input[1:0] TEND;

reg [2:0] quadA_delayed, quadB_delayed;
always @(posedge clk) 
	quadA_delayed <= {quadA_delayed[1:0], quadA};
	
always @(posedge clk) 
	quadB_delayed <= {quadB_delayed[1:0], quadB};

wire count_enable = quadA_delayed[1] ^ quadA_delayed[2] ^ quadB_delayed[1] ^ quadB_delayed[2];
wire count_direction = quadA_delayed[1] ^ quadB_delayed[2];

reg [15:0] count;
reg reset = 1'b0;

always @(posedge clk)
	reset = ((CMD == 1) && (TEND));

always @(posedge clk)
begin
	if (reset)
	begin
		count = 16'b0000000000000000;
	end
	else
	begin	
		if(count_enable)
	   begin
			if (count_direction) 
				count<=count+1; 
			else count<=count-1;
		end
	end
end

endmodule