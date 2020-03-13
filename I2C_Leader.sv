module I2C_Leader(/*CLK_800KHz,*/CLK_50MHz, RESET, SDA, SCL, WP, CACHE);
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
	//input CLK_800KHz; 	// Control clock from DE2-115 COMMENTED OUT ONLY TEMPORARILY
	//	wire CLK_50kHz; //TEMPORARY
	reg CLKLogic;


	input RESET; // Module reset line
	input CLK_50MHz; //TEMPORARY
	// I2C comm lines
	output reg SCL;
	inout SDA;
	// EEPROM config lines
	output WP; // EEPROM Write-Protect

	// Parameters
	//wire useAckPolling = 1; // enable continuous polling the Acknowledge bit intead of waiting Twc
	//wire usePageWrites = 1; // enable page write mode instead of byte write mode

	parameter 	ControlByte 	= 3'b000,
	AddressMSBByte 	= 3'b001,
	AddressLSBByte 	= 3'b010,
	DataByte 		= 3'b011,
	Done			= 3'b100;

	// Internal Wiring
	reg SDALogicCLK;
	reg counter;
	reg EndFlag;
	reg [2:0] ByteState;
	reg [4:0] State;
	reg sdaEnable;
	reg sdaCACHE;
	wire [14:0] MemLoc;
	reg [9:0] DataIndex;

	reg isFirstClock;

	// Continuous Logic
	assign SDA = (sdaEnable) ? sdaCACHE : 1'bz;
	assign WP = 0;
	assign MemLoc = 0;

	reg [31:0] ClockCounter;

	// Sequential Logic
	//Generate CLKLogic
	always @ (posedge CLK_50MHz or negedge RESET)
	begin
		if (RESET == 0)
			begin
				CLKLogic <= 0;
				ClockCounter <= 0;
			end

		else
			begin	// TODO fix clocks
				if (ClockCounter >= 32'd10000) //CHANGE THIS BEFORE UPLOAD, CLOCK IS TOO FAST FOR DEVICE.  HIGH SPEED FOR SIMULATION ONLY (4 for HI, 499 for LO)
					begin
						ClockCounter <= 32'd0;
						CLKLogic <= !CLKLogic;
					end
				else
					ClockCounter = ClockCounter + 1;
			end
	end


	//Generate SCL
	//always @ (posedge /*CLK_800KHz*//*CLKLogic*/CLK_50MHz or negedge RESET)
	/*begin

		if (RESET == 0)
			begin
				SCL <= 1;
				isFirstClock <= 0;
			end
		else
			begin
				if (isFirstClock == 0)
					begin
						isFirstClock <= 1;				
						SCL <= 1;
					end
				else
					begin
						SCL <= ~SCL;
						isFirstClock <= 1;				
					end
			end // End if/else block for resetting
	end*/

	always @ (negedge CLKLogic or negedge RESET) begin
		if(!RESET)
			begin
				sdaCACHE <= 1; //ready to be pulled low for a START bit
				sdaEnable <= 1;
				State <= 0;
				ByteState <= 0;
				DataIndex <= 0;
				EndFlag <= 0;
				
// Testing
				SCL <= 1;
				isFirstClock <= 0;
			end
		else
			begin
				if (isFirstClock == 0)
					begin
						isFirstClock <= 1;				
						SCL <= 1;
					end
				else
					begin
						SCL <= ~SCL;
						isFirstClock <= 1;				
					end
// end testing
				
				case(ByteState)
					ControlByte:
					begin
						case(State)
							5'b0:		begin
								sdaCACHE <= 0;
								sdaEnable <= 1;
							end
							5'd1: 	sdaCACHE <= 1;
							5'd2:		; //Nothing
							5'd3:		sdaCACHE <= 0;
							5'd4:		; //Nothing
							5'd5:		sdaCACHE <= 1;
							5'd6:		; //Nothing
							5'd7:		sdaCACHE <= 0;
							5'd8:		; //Nothing
							5'd9:		sdaCACHE <= 0;
							5'd10:	; //Nothing
							5'd11:	sdaCACHE <= 0;
							5'd12:	; //Nothing
							5'd13:	sdaCACHE <= 0;
							5'd14:	; //Nothing
							5'd15:	sdaCACHE <= 0;
							5'd16:	; //Nothing
							default:	begin
								sdaEnable <= 0;
								ByteState <= AddressMSBByte;
							end
						endcase
						if(State >= 5'd17)
							State <= 0;
						else
							State <= State + 1;

					end


					AddressMSBByte:
					begin
						case(State)
							5'd0:		;
							5'd1: begin
								sdaCACHE <= 1; //Don't care
								sdaEnable <= 1;
							end
							5'd2:		; //Nothing
							5'd3:		sdaCACHE <= MemLoc[14];
							5'd4:		; //Nothing
							5'd5:		sdaCACHE <= MemLoc[13];
							5'd6:		; //Nothing
							5'd7:		sdaCACHE <= MemLoc[12];
							5'd8:		; //Nothing
							5'd9:		sdaCACHE <= MemLoc[11];
							5'd10:	; //Nothing
							5'd11:	sdaCACHE <= MemLoc[10];
							5'd12:	; //Nothing
							5'd13:	sdaCACHE <= MemLoc[9];
							5'd14:	; //Nothing
							5'd15:	sdaCACHE <= MemLoc[8];
							5'd16:	; //Nothing
							default:	begin
								sdaEnable <= 0;
								ByteState <= AddressLSBByte;
							end
						endcase
						if(State >= 5'd17)
							State <= 0;
						else
							State <= State + 1;
					end


					AddressLSBByte:
					begin
						case(State)
							5'd0: 	;
							5'd1: begin
								sdaCACHE <= MemLoc[7];
								sdaEnable <= 1;
							end
							5'd2:		; //Nothing
							5'd3:		sdaCACHE <= MemLoc[6];
							5'd4:		; //Nothing
							5'd5:		sdaCACHE <= MemLoc[5];
							5'd6:		; //Nothing
							5'd7:		sdaCACHE <= MemLoc[4];
							5'd8:		; //Nothing
							5'd9:		sdaCACHE <= MemLoc[3];
							5'd10:	; //Nothing
							5'd11:	sdaCACHE <= MemLoc[2];
							5'd12:	; //Nothing
							5'd13:	sdaCACHE <= MemLoc[1];
							5'd14:	; //Nothing
							5'd15:	sdaCACHE <= MemLoc[0];
							5'd16:	; //Nothing
							default:	begin
								sdaEnable <= 0;
								ByteState <= DataByte;
							end
						endcase
						if(State >= 5'd17)
							State <= 0;
						else
							State <= State + 1;
					end


					DataByte:
					begin
						case(State)
							5'd0:		;
							5'd1: 	begin
								sdaCACHE <= CACHE[DataIndex]; //Don't care
								sdaEnable <= 1;
							end
							5'd2:		; //Nothing
							5'd3:		sdaCACHE <= CACHE[DataIndex + 1];
							5'd4:		; //Nothing
							5'd5:		sdaCACHE <= CACHE[DataIndex + 2];
							5'd6:		; //Nothing
							5'd7:		sdaCACHE <= CACHE[DataIndex + 3];
							5'd8:		; //Nothing
							5'd9:		sdaCACHE <= CACHE[DataIndex + 4];
							5'd10:	; //Nothing
							5'd11:	sdaCACHE <= CACHE[DataIndex + 5];
							5'd12:	; //Nothing
							5'd13:	sdaCACHE <= CACHE[DataIndex + 6];
							5'd14:	; //Nothing
							5'd15:	sdaCACHE <= CACHE[DataIndex + 7];
							5'd16:	; //Nothing
							default:	begin
								sdaEnable <= 0; //Acknowledge
								DataIndex <= DataIndex + 9'd8;
							end
						endcase

						if(DataIndex >= 9'd504 && State >= 5'd17)
							begin
								ByteState <= Done;
								State <= 5'd0;
							end

						else if(State >= 5'd17)
							State <= 5'd0;

						else
							State <= State + 1;

					end


					Done:
					begin
						if(!EndFlag)
							case(State)
								5'd0: ;
								5'd1: sdaEnable <= 1;
								5'd2:	begin
									sdaCACHE <= 1;
									EndFlag <= 1;
								end
							endcase
						else
							begin
								sdaEnable <= 1;
								State <= 0;
								sdaCACHE <= 1;
							end

						State <= State + 5'd1;
					end

					default:
					ByteState <= ControlByte;
				endcase
			end
	end
endmodule