module top(CLCK, SCL, SDA, CNT1A, CNT1B, CNT2A,CNT2B, CNT3A, CNT3B, CNT4A, CNT4B);

input CLCK;
input SCL;
inout SDA;
input CNT1A;
input CNT1B;
input CNT2A;
input CNT2B;
input CNT3A;
input CNT3B;
input CNT4A;
input CNT4B;

wire[15:0] CNTR1;
wire[15:0] CNTR2;
wire[15:0] CNTR3;
wire[15:0] CNTR4;
wire[7:0] CMD;
wire[1:0] TEND;

quad counter1(.clk   (CLCK),
			     .quadA (CNT1A),
				  .quadB (CNT1B),
				  .count (CNTR1),
				  .CMD   (CMD),
				  .TEND  (TEND));
				  
quad counter2(.clk   (CLCK),
			     .quadA (CNT2A),
				  .quadB (CNT2B),
				  .count (CNTR2),
				  .CMD   (CMD),
				  .TEND  (TEND));
				  
quad counter3(.clk   (CLCK),
			     .quadA (CNT3A),
				  .quadB (CNT3B),
				  .count (CNTR3),
				  .CMD   (CMD),
				  .TEND  (TEND));
				  
quad counter4(.clk   (CLCK),
			     .quadA (CNT4A),
				  .quadB (CNT4B),
				  .count (CNTR4),
				  .CMD   (CMD),
				  .TEND  (TEND));
	
I2CSlave(.CLCK  (CLCK), 
         .SCL   (SCL), 
			.SDA   (SDA),
			.CNTR1 (CNTR1),
			.CNTR2 (CNTR2),
			.CNTR3 (CNTR3),
			.CNTR4 (CNTR4),
			.CMD   (CMD),
			.TEND  (TEND));

endmodule