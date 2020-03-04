module I2C_Leader(CLK_50MHz, RESET, SDA, SCL, WP );
	// Module to connect 24LC256-I/P EEPROM
	
	// Cicuit notes:
	//	- WP, SCL, SDA need pull-up R to Vcc between 2k and 10k (speed dependent)
	//		- See AN1028
	//	- Vcc/ GND need 0.1uF Decoupling Capacitor to filter PSU noise
	//	- Address Pins should be tied to GND or VCC to configure chip
	//		- This configuration will be embedded in the control byte
	//	- Vss tied to GND
	//	- Vcc > Vmin during writes
	
	// I/O
	// FPGA control lines
	input CLK_50MHz; 	// Control clock from DE2-115
	input RESET;		// Module reset line
	// I2C comm lines
	inout SCL;
	inout SDA;
	// EEPROM config lines
	output WP; 			// EEPROM Write-Protect
	
	// Parameters
	wire useAckPolling = 1; // enable continuous polling the Acknowledge bit intead of waiting Twc
	wire usePageWrites = 1; // enable page write mode instead of byte write mode
	
	// Internal Wiring
	
	
	
endmodule