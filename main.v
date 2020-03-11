module main(SW, LEDR, GPIO, CLK_50MHz);
	// Top-Level module for that data-logger project
	
	// I/O
	input SW[0:0];
	input CLK_50MHz;
	inout GPIO[23:0];
	output LEDR[0:0];
	
	// Internal Wiring
	reg CACHE[511:0];
	reg CacheIndex[4:0];
	wire RESET;
	wire [7:0] Sample_word;
	
	
	
	// Internal Logic
	
	// Module Instantiation
	SPI_Leader ADC_Controller(
		// Inputs
		.CLK_50MHz(CLK_50MHz), 
		.Dout(GPIO[0]), 
		.RESET(RESET), 
		
		// Outputs
		.CLKsample(GPIO[1]), 
		.Din(GPIO[2]), 
		.CS(GPIO[3]), 
		.Sample_word(Sample_word)
	);
	I2C_Leader EEPROM_Controller(CLK_800KHz, RESET, SDA, SCL, WP, CACHE);
	
	// Combinatorial
	assign RESET = SW[0];
	assign LEDR[0] = RESET;
	
	// Procedural
	always @ (Sample_word or negedge RESET)
		begin
			
		end
			
	
	
	
endmodule