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
	
	
	// Internal Logic
	
	// Module Instantiation
	SPI_Leader ADC_Controller(CLK_50MHz, CLKsample, Din, Dout, CS, RESET, Sample_word);
	I2C_Leader EEPROM_Controller(CLK_800KHz, RESET, SDA, SCL, WP, CACHE);
	
	// Combinatorial
	assign RESET = SW[0];
	assign LEDR[0] = RESET;
	
	// Procedural
	always @(Sample_word)
		begin
			
		end
			
	
	
	
endmodule