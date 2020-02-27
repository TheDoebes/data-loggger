module SPI_Leader(CLK_50MHz, CLKsample, Din, Dout, CS);
	
	// I/O - Labels corrospond to MCP3002 Datasheet
	input CLK_50MHz;
	input Dout;
	output CLKsample;
	output Din;
	output CS;
	
	// Internal Wiring
	reg [4:0] stateCounter;
	
	// Logic
	
	

endmodule;