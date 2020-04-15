module data_logger(SW, LEDR, SCL,SDA,WP, CLK_50MHz, Dout,Din,CS,CLKsample, LEDG, LEDG8);
	// Top-Level module for that data-logger project


	// I/O
	input SW;
	input CLK_50MHz;
	output LEDR;
	output [7:0] LEDG;
	output LEDG8;
	
	// I/O - Labels corrospond to MCP3002 Datasheet
	input Dout; // Serialized ADC output
	output logic CLKsample; // Control clock for ADC
	output logic Din; // Config line for ADC
	output logic CS; // Chip Enable for ADC, Active low
	
	// I2C comm lines
	output logic SCL;
	inout SDA;
	// EEPROM config lines
	output WP; // EEPROM Write-Protect
	
	parameter 	
		ControlByte 	= 3'b000,
		AddressMSBByte 	= 3'b001,
		AddressLSBByte 	= 3'b010,
		DataByte 		= 3'b011,
		Done			= 3'b100;

	// Internal Wiring
	logic [511:0] CACHE;	// Stores a page of sampled values
	logic [9:0] CacheIndex; // Indexes through cache, a page of values
	logic [9:0] CacheIndex_next; // Helper var for incrementing cacheindex
	wire RESET;				// Reset line
	logic EEPROM_RST;		// reset line specifically for eeprom
	
	logic [7:0] Sample_word; // One sample of the signal
	logic sample_available; // Goes low whenever sample_word changes to something valid
	logic [4:0] timeCounter; // 50MHz Counter, resets at 3.125 MHz
	logic [4:0] timeCounter_next; // helper var to increment timeCounter
	logic [4:0] stateCounter; // 3.125 MHz counter, resets at every sample
	logic [4:0] stateCounter_next; // Helper variable for incrementing stateCounter
	logic [7:0] sample; // Shift register to deserialize sample bits
	
	logic CLK_ROM_Tx; // signal used to time the eeprom writing state machine
	logic [31:0] ROM_ClockCounter; // Used to create CLK_ROM_Tx
	
	logic EndFlag; // Used for sending the stop bit??
	logic [2:0] ByteState; // state machine var for which part of writing the rom_tx is in
	logic [4:0] State; // state machine var for sub cases in rom_tx
	logic [4:0] State_next;
	
	logic sdaEnable; // Used to toogle sda between input/output modes w/ high z
	logic sdaCACHE; // caches sda for writing with sdaEnable
	logic [9:0] DataIndex; // Indexes through cache to write each byte to the eeprom

	logic isFirstClock; // Used to keep scl high an extra cycle after resetting
	
	logic doneLEDG;


// Internal Logic
	
	// Continuous Logic
	assign SDA = (sdaEnable) ? sdaCACHE : 1'bz;
	assign WP = 0;
	assign RESET = SW;
	assign LEDR = !RESET;
	assign LEDG = Sample_word;
	assign LEDG8 = doneLEDG;
	
	
//MCP3002 ADC

	// Interface with the ADC device every CLKsample
	always @(*) begin
		stateCounter_next = stateCounter + 5'b1;
	end
	
	always @ (posedge CLKsample or negedge RESET)
	begin
		if (!RESET)
			begin
				stateCounter <= 5'd16; // Make sure shutdown time of 310ns is achieved 
				CS <= 1'b1;
				Din <= 1'b1;
				sample <= 8'd0;
				Sample_word <= 8'd0;
				sample_available <= 1'b1;				
			end
		else
			begin
				case (stateCounter) // Manipulate the control lines each clock cycle
				// Startup segment
					5'd0	:
					begin
						stateCounter <= stateCounter_next;
						CS <= 1'b1;
						Din <= 1'b1; // Don't care
					end

					// Config segment
					5'd1	:
					begin
						stateCounter <= stateCounter_next;
						CS <= 1'b0; // Must be kept low for at least 100ns before next CLKsample
						Din <= 1'b1; // Startup condition
					end
					5'd2	:
					begin
						stateCounter <= stateCounter_next;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Selects SIGNULAR mode
					end
					5'd3	:
					begin
						stateCounter <= stateCounter_next;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Selects CH1 for analog input
					end
					5'd4	: // duplicated this state to add an additional delay, fixing an off by one. not sure why this occurred.
					begin
						stateCounter <= stateCounter_next;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Selects MSB first mode
					end
					5'd5	: 
					begin
						stateCounter <= stateCounter_next;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Selects MSB first mode
					end
					// Begin reading sample bit
					5'd6	:
					begin
						stateCounter <= stateCounter_next;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						// Dout is null here
					end
					5'd7	:
					begin
						stateCounter <= stateCounter_next;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						sample[0] <= Dout; //Begin shifting Dout into Sample
					end
					5'd8	:
					begin
						stateCounter <= stateCounter_next;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						sample[1] <= Dout; // Shift Dout into sample
					end
					5'd9	:
					begin
						stateCounter <= stateCounter_next;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						sample[2] <= Dout; // Shift Dout into sample
					end
					5'd10	:
					begin
						stateCounter <= stateCounter_next;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						sample[3] <= Dout; // Shift Dout into sample
					end
					5'd11	:
					begin
						stateCounter <= stateCounter_next;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						sample[4] <= Dout; // Shift Dout into sample
					end
					5'd12	:
					begin
						stateCounter <= stateCounter_next;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						sample[5] <= Dout; // Shift Dout into sample
					end
					5'd13	:
					begin
						stateCounter <= stateCounter_next;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						sample[6] <= Dout; // Shift Dout into sample
					end
					5'd14	:
					begin
						stateCounter <= stateCounter_next;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						sample[7] <= Dout; // Shift Dout into sample
						sample_available <= 1'b1;
					end

					// Cutoff sample conversion
					5'd15	:
					begin
						stateCounter <= stateCounter_next;
						CS <= 1'b1; // Goes high for at least 310 ns for shutdown time
						Din <= 1'b1; // Don't Care
						Sample_word <= sample;
						sample_available <= 1'b0;
					end
					5'd16	:
					begin
						//stateCounter <= stateCounter_next;
						CS <= 1'b1; // Goes high for at least 310 ns for shutdown time
						Din <= 1'b1; // Don't Care
						stateCounter <= 5'd0;
						sample_available <= 1'b1;
					end

					default	: stateCounter <= 5'd0;
				endcase
			end	// End if/else block for resetting

	end


	// Create a 3.125 MHz signal
	always @(*) begin
		timeCounter_next = timeCounter + 5'b1;
	end
	always @ (posedge CLK_50MHz or negedge RESET)
	begin

		if (RESET == 0)
			begin
				CLKsample <= 0;
				timeCounter <= 5'd0;
			end
		else
			begin
				timeCounter <= timeCounter_next;
				if (timeCounter == 5'd8)
				begin
					CLKsample <= !CLKsample;
					timeCounter <= 5'd0;
				end
			end // End if/else block for resetting
	end
	
	
//24LC256-I/P EEPROM
	

	// Sequential Logic
	//Generate CLK_ROM_Tx
	always @ (posedge CLK_50MHz or negedge EEPROM_RST)
	begin
		if (!EEPROM_RST)
			begin
				CLK_ROM_Tx <= 0;
				ROM_ClockCounter <= 0;
			end

		else
			begin	// TODO fix clocks
				if (ROM_ClockCounter >= 32'd10000) //CHANGE THIS BEFORE UPLOAD, CLOCK IS TOO FAST FOR DEVICE.  HIGH SPEED FOR SIMULATION ONLY (4 for HI, 499 for LO)
					begin
						ROM_ClockCounter <= 32'd0;
						CLK_ROM_Tx <= !CLK_ROM_Tx;
					end
				else
					ROM_ClockCounter = ROM_ClockCounter + 1;
			end
	end


	always @(*) begin
		State_next = State + 5'd1;
	end
	always @ (negedge CLK_ROM_Tx or negedge EEPROM_RST) begin
		if(!EEPROM_RST)
			begin
				sdaCACHE <= 1; //ready to be pulled low for a START bit
				sdaEnable <= 1;
				State <= 0;
				ByteState <= 0;
				DataIndex <= 0;
				EndFlag <= 0;
				
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
							State <= State_next;

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
							5'd3:		sdaCACHE <= 1'b0;
							5'd4:		; //Nothing
							5'd5:		sdaCACHE <= 1'b0;
							5'd6:		; //Nothing
							5'd7:		sdaCACHE <= 1'b0;
							5'd8:		; //Nothing
							5'd9:		sdaCACHE <= 1'b0;
							5'd10:	; //Nothing
							5'd11:	sdaCACHE <= 1'b0;
							5'd12:	; //Nothing
							5'd13:	sdaCACHE <= 1'b0;
							5'd14:	; //Nothing
							5'd15:	sdaCACHE <= 1'b0;
							5'd16:	; //Nothing
							default:	begin
								sdaEnable <= 0;
								ByteState <= AddressLSBByte;
							end
						endcase
						if(State >= 5'd17)
							State <= 0;
						else
							State <= State_next;
					end


					AddressLSBByte:
					begin
						case(State)
							5'd0: 	;
							5'd1: begin
								sdaCACHE <= 1'b0;
								sdaEnable <= 1;
							end
							5'd2:		; //Nothing
							5'd3:		sdaCACHE <= 1'b0;
							5'd4:		; //Nothing
							5'd5:		sdaCACHE <= 1'b0;
							5'd6:		; //Nothing
							5'd7:		sdaCACHE <= 1'b0;
							5'd8:		; //Nothing
							5'd9:		sdaCACHE <= 1'b0;
							5'd10:	; //Nothing
							5'd11:	sdaCACHE <= 1'b0;
							5'd12:	; //Nothing
							5'd13:	sdaCACHE <= 1'b0;
							5'd14:	; //Nothing
							5'd15:	sdaCACHE <= 1'b0;
							5'd16:	; //Nothing
							default:	begin
								sdaEnable <= 0;
								ByteState <= DataByte;
							end
						endcase
						if(State >= 5'd17)
							State <= 0;
						else
							State <= State_next;
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
							State <= State_next;

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

						State <= State_next;
					end

					default:
					ByteState <= ControlByte;
				endcase
			end
	end
	

	// Procedural "glue" logic
	always @(*) begin
		CacheIndex_next = CacheIndex + 9'd8;;
	end
	
	always @ (negedge sample_available or negedge RESET) // TODO make depend only on sample word
	begin
		if (RESET == 0)
			begin
				CACHE <= 511'd0;
				CacheIndex <= 9'd0;
				EEPROM_RST <= 0;
				doneLEDG <= 0;
			end
		else
			begin
				if (CacheIndex < 9'd64)
					begin
						CACHE[CacheIndex + 9'd0] <= Sample_word[8'd0];
						CACHE[CacheIndex + 9'd1] <= Sample_word[8'd1];
						CACHE[CacheIndex + 9'd2] <= Sample_word[8'd2];
						CACHE[CacheIndex + 9'd3] <= Sample_word[8'd3];
						CACHE[CacheIndex + 9'd4] <= Sample_word[8'd4];
						CACHE[CacheIndex + 9'd5] <= Sample_word[8'd5];
						CACHE[CacheIndex + 9'd6] <= Sample_word[8'd6];
						CACHE[CacheIndex + 9'd7] <= Sample_word[8'd7];
						
						CacheIndex <= CacheIndex_next;
						EEPROM_RST <= 0; // Set to zero later
						doneLEDG <= 0;
						
					end
				else
					begin
						CacheIndex <= 9'd64;
						EEPROM_RST <= 1; // Enable the EEPROM and let it write a page
						doneLEDG <= 1;
					end
			end
	end

endmodule