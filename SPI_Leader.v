module SPI_Leader(CLK_50MHz, CLKsample, Din, Dout, CS, RESET);
	
	// I/O - Labels corrospond to MCP3002 Datasheet
	input CLK_50MHz;
	input Dout;
	output  reg CLKsample;
	output Din;
	output CS;
	
	// Internal Wiring
	reg [4:0] timeCounter;
	reg [4:0] stateCounter;
	
	// Logic
	
	// Interface with the device
	always @ (*)
	begin
		if (RESET)
		begin
			stateCounter <= 5'd15;
		end
				
		case (stateCounter)
			5'd0	: 
			begin
				stateCounter = 1 + stateCounter;
				CS <= 1'b1;
				
			end
			
			default	: stateCounter <= 5'd0;
		endcase
	end	
	
	// Create a 3.125 MHz signal
	always @ (CLK_50MHz) 
	begin
		timeCounter <= timeCounter + 1;
		if (timeCounter == 5'd8)
			begin
				CLKsample <= !CLKsample;
				timeCounter <= 5'd0;
			end
	end			
	

endmodule;