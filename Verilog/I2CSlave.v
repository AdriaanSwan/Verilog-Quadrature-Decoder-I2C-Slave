module I2CSlave(CLCK, SCL, SDA, CNTR1, CNTR2, CNTR3, CNTR4, CMD, TEND);

input CLCK;
input SCL;
inout SDA;
input[15:0] CNTR1;
input[15:0] CNTR2;
input[15:0] CNTR3;
input[15:0] CNTR4;
output[7:0] CMD;
output[1:0] TEND;

//Device's slave address
parameter slaveaddress = 7'b1110010;

//Count of bytes to be sent, 2 bytes per counter
reg[3:0] valuecnt = 4'b1000; 

//Cached counts for period of I2C transaction if an address match happend
reg[15:0] CHCNTR [0:3];

//Synch SCL edge to the CPLD clock
reg [2:0] SCLSynch = 3'b000;  
always @(posedge CLCK) 
	SCLSynch <= {SCLSynch[1:0], SCL};
	
wire SCL_posedge = (SCLSynch[2:1] == 2'b01);  
wire SCL_negedge = (SCLSynch[2:1] == 2'b10);  

//Synch SDA to the CPLD clock
reg [2:0] SDASynch = 3'b000;
always @(posedge CLCK) 
	SDASynch <= {SDASynch[1:0], SDA};
	
wire SDA_synched = SDASynch[0] & SDASynch[1] & SDASynch[2];

//Detect start and stop
reg start = 1'b0;
always @(negedge SDA)
	start = SCL;

reg stop = 1'b0;
always @(posedge SDA)
	stop = SCL;

//Set cycle state 
reg incycle = 1'b0;
reg[1:0] TEND = 1'b0; 
always @(posedge start or posedge stop)
	if (start)
	begin
		if (incycle == 1'b0)
		begin
			incycle = 1'b1;
			TEND = 1'b0;
			CHCNTR[0] <= CNTR1;
			CHCNTR[1] <= CNTR2;
			CHCNTR[2] <= CNTR3;
			CHCNTR[3] <= CNTR4;
		end
	end
	else if (stop)
	begin
		if (incycle == 1'b1)
		begin
			incycle = 1'b0;
			TEND = 1'b1;
		end
	end
	
//Address and incomming data handling
reg[7:0] bitcount = 8'b00000000;
reg[6:0] address = 7'b0000000;
reg[7:0] CMD = 8'b00000000;
reg[1:0] rw = 1'b0;
reg[1:0] addressmatch = 1'b0;
always @(posedge SCL_posedge or negedge incycle)
	if (~incycle)	
	begin
		//Reset the bit counter at the end of a sequence
		bitcount = 0;
	end
	else
   begin
		bitcount = bitcount + 1'b1;
		
	   //Get the address
		if (bitcount < 8)
			address[7 - bitcount] = SDA_synched;
		
		if (bitcount == 8)
		begin
			rw = SDA_synched;
			addressmatch = (slaveaddress == address) ? 1'b1 : 1'b0;
		end
			
		if ((bitcount > 9) & (~rw))
			//Receive data (currently only one byte)
			CMD[17 - bitcount] = SDA_synched;
	end
	
//ACK's and out going data
reg sdadata = 1'bz; 
reg [3:0] currvalue = 4'b0000;
reg [3:0] byteindex = 4'b0000;
reg [7:0] bitindex = 8'b00000000;
always @(posedge SCL_negedge) 
	//ACK's
	if (((bitcount == 8) | ((bitcount == 17) & ~rw)) & (addressmatch))
	begin
		sdadata = 1'b0;
		currvalue = 4'b0000;
		byteindex = currvalue / 2'b10;
		bitindex = 4'b1111;
	end
	//Data
	else if ((bitcount >= 9) & (rw) & (addressmatch) & (currvalue < valuecnt))
	begin
		//Send Data  
		if (((bitcount - 9) - (currvalue * 9)) == 8)
		begin
			//Release SDA so master can ACK/NAK
			sdadata = 1'bz;
			currvalue = currvalue + 1'b1;
			byteindex = currvalue / 2'b10;
			
			if (bitindex == 0)
				bitindex = 4'b1111;
		end
		else
		begin 
			sdadata = CHCNTR[byteindex][bitindex];
			bitindex = bitindex - 1'b1;
		end
	end
	//Nothing (cause nothing tastes like fresca)
	else sdadata = 1'bz;
	
assign SDA = sdadata;

endmodule