module I2C_Leader(CLK_800KHz, RESET, SDA, SCL, WP, CACHE);
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
	input [511:0] CACHE;
	// FPGA control lines
	input CLK_800KHz; 	// Control clock from DE2-115
	input RESET;		// Module reset line
	// I2C comm lines
	output reg SCL;
	inout SDA;
	// EEPROM config lines
	output WP; 			// EEPROM Write-Protect
	
	// Parameters
	wire useAckPolling = 1; // enable continuous polling the Acknowledge bit intead of waiting Twc
	wire usePageWrites = 1; // enable page write mode instead of byte write mode
	
	parameter 	ControlByte 	= 3'b000,
				AddressMSBByte 	= 3'b001,
				AddressLSBByte 	= 3'b010,
				DataByte 		= 3'b011,
				Done			= 3'b100;
				
	// Internal Wiring
	reg SDALogicCLK;
	reg counter;
	reg [2:0] ByteState;
	reg [4:0] State;
	reg sdaEnable;
	reg sdaCACHE;
	reg [14:0] MemLoc;
	reg [5:0] DataIndex;
	
	assign SDA = (sdaEnable) ? sdaCACHE : 1'bz;
	
	//Generate SCL
	always @ (posedge CLK_800KHz or negedge RESET)
	begin

		if (RESET == 0)
			begin
				SCL <= 0;
				counter <= 1'd0;
			end
		else
			begin
				counter <= counter + 1;
				if (counter)
				begin
					SCL <= !SCL;
					counter <= 1'd0;
				end
			end // End if/else block for resetting
	end
	
	always @ (posedge CLK_800KHz) begin
		
		case(ByteState)
			ControlByte:
			begin
				case(State)
					5'b0:		sdaCACHE <= 0;
					5'd1: 	sdaCACHE <= 1;
					5'd2:		;//Nothing
					5'd3:		sdaCACHE <= 0;
					5'd4:		;//Nothing
					5'd5:		sdaCACHE <= 1;
					5'd6:		;//Nothing
					5'd7:		sdaCACHE <= 0;
					5'd8:		;//Nothing
					5'd9:		sdaCACHE <= 0;
					5'd10:	;//Nothing
					5'd11:	sdaCACHE <= 0;
					5'd12:	;//Nothing
					5'd13:	sdaCACHE <= 0;
					5'd14:	;//Nothing
					5'd15:	sdaCACHE <= 0;
					5'd16:	;//Nothing
					5'd17:	begin
						sdaEnable <= 0;
						ByteState <= AddressMSBByte;
						end
				endcase
				if(State >= 5'd18)
					State <= 0;
				else
					State <= State + 1;
					
			end
			AddressMSBByte:
			begin
				case(State)
					5'd0:		;//Nothing
					5'd1: 	sdaCACHE <= 1; //Don't care
					5'd2:		;//Nothing
					5'd3:		sdaCACHE <= MemLoc[14];
					5'd4:		;//Nothing
					5'd5:		sdaCACHE <= MemLoc[13];
					5'd6:		;//Nothing
					5'd7:		sdaCACHE <= MemLoc[12];
					5'd8:		;//Nothing
					5'd9:		sdaCACHE <= MemLoc[11];
					5'd10:	;//Nothing
					5'd11:	sdaCACHE <= MemLoc[10];
					5'd12:	;//Nothing
					5'd13:	sdaCACHE <= MemLoc[9];
					5'd14:	;//Nothing
					5'd15:	sdaCACHE <= MemLoc[8];
					5'd16:	;//Nothing
					5'd17:	begin
						sdaEnable <= 0;
						ByteState <= AddressLSBByte;
						end
				endcase
				if(State >= 5'd18)
					State <= 0;
				else
					State <= State + 1;
			end	
			AddressLSBByte:
			begin
				case(State)
					5'd0:		;//Nothing
					5'd1: 	sdaCACHE <= MemLoc[7]; //Don't care
					5'd2:		;//Nothing
					5'd3:		sdaCACHE <= MemLoc[6];
					5'd4:		;//Nothing
					5'd5:		sdaCACHE <= MemLoc[5];
					5'd6:		;//Nothing
					5'd7:		sdaCACHE <= MemLoc[4];
					5'd8:		;//Nothing
					5'd9:		sdaCACHE <= MemLoc[3];
					5'd10:	;//Nothing
					5'd11:	sdaCACHE <= MemLoc[2];
					5'd12:	;//Nothing
					5'd13:	sdaCACHE <= MemLoc[1];
					5'd14:	;//Nothing
					5'd15:	sdaCACHE <= MemLoc[0];
					5'd16:	;//Nothing
					5'd17:	begin
						sdaEnable <= 0;
						ByteState <= DataByte;
						end
				endcase
				if(State >= 5'd18)
					State <= 0;
				else
					State <= State + 1;
			end	
			DataByte:
			begin
				case(State)
					5'd0:		;//Nothing
					5'd1: 	sdaCACHE <= CACHE[DataIndex]; //Don't care
					5'd2:		;//Nothing
					5'd3:		sdaCACHE <= CACHE[DataIndex + 1];
					5'd4:		;//Nothing
					5'd5:		sdaCACHE <= CACHE[DataIndex + 2];
					5'd6:		;//Nothing
					5'd7:		sdaCACHE <= CACHE[DataIndex + 3];
					5'd8:		;//Nothing
					5'd9:		sdaCACHE <= CACHE[DataIndex + 4];
					5'd10:	;//Nothing
					5'd11:	sdaCACHE <= CACHE[DataIndex + 5];
					5'd12:	;//Nothing
					5'd13:	sdaCACHE <= CACHE[DataIndex + 6];
					5'd14:	;//Nothing
					5'd15:	sdaCACHE <= CACHE[DataIndex + 7];
					5'd16:	;//Nothing
					5'd17:	begin
						sdaEnable <= 0;
						DataIndex <= DataIndex + 8;
						end
				endcase
				
				if(DataIndex == 56 && State >= 5'd18)
					ByteState <= Done;
					
				else if(State >= 5'd18)
					State <= 5'd0;
					
				else
					State <= State + 1;
					
				
			end
			Done:
			begin
				sdaCACHE <= 1'b1;if(DataIndex == 56 && State >= 5'd18)
					ByteState <= Done;
			end
		endcase
	end
endmodule