module I2C_Leader(CLK_50MHz, WP, );
	// Module to connect 24LC256-I/P EEPROM
	// Cicuit notes:
	//	- WP, SCL, SDA need pull-up R to Vcc between 2k and 10k (speed dependent)
	//		- See AN1028
	//	- Vcc/ GND need 0.1uF Decoupling Capacitor to filter PSU noise
	//	- Address Pins should be tied to GND or VCC to configure chip
	//		- This configuration will be embedded in the control byte
	//	- Vss tied to GND
	
	// I/O
	input CLK_50MHz; 	// Control clock from DE2-115
	output WP; 			// EEPROM Write-Protect
	
	
endmodule