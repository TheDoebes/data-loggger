module SPI_Leader(CLK_50MHz, CLKsample, Din, Dout, CS, RESET, Sample_word);

	// SPI_Leader - control module for MCP3002 ADC

	// I/O - Labels corrospond to MCP3002 Datasheet
	input CLK_50MHz; // Driver clock for this module
	input Dout; // Serialized ADC output
	input RESET; // Active low reset signal
	output reg CLKsample; // Control clock for ADC
	output reg Din; // Config line for ADC
	output reg CS; // Chip Enable for ADC, Active low
	output reg [7:0] Sample_word; // Sampled signal

	// Internal Wiring
	reg [4:0] timeCounter; // 50MHz Counter, resets at 3.125 MHz
	reg [4:0] stateCounter; // 3.125 MHz counter, resets at every sample
	reg [7:0] sample; // Shift register to deserialize sample bits

	// Logic

	// Interface with the ADC device every CLKsample
	always @ (posedge CLKsample or negedge RESET)
	begin
		if (RESET == 0)
			begin
				stateCounter <= 5'd15; // Make sure shutdown time of 310ns is achieved 
				CS <= 1'b1;
				Din <= 1'b1;
				sample <= 8'd0;
				Sample_word <= 8'd0;
			end
		else
			begin
				case (stateCounter) // Manipulate the control lines each clock cycle
				// Startup segment
					5'd0	:
					begin
						stateCounter <= stateCounter + 1;
						CS <= 1'b1;
						Din <= 1'b1; // Don't care
					end

					// Config segment
					5'd1	:
					begin
						stateCounter <= stateCounter + 1;
						CS <= 1'b0; // Must be kept low for at least 100ns before next CLKsample
						Din <= 1'b1; // Startup condition
					end
					5'd2	:
					begin
						stateCounter <= stateCounter + 1;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Selects SIGNULAR mode
					end
					5'd3	:
					begin
						stateCounter <= stateCounter + 1;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Selects CH1 for analog input
					end
					5'd4	: // TODO duplicate this state to add an additional delay, fixing an off by one
					begin
						stateCounter <= stateCounter + 1;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Selects MSB first mode
					end

					// Begin reading sample bit
					5'd5	:
					begin
						stateCounter <= stateCounter + 1;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						// Dout is null here
					end
					5'd6	:
					begin
						stateCounter <= stateCounter + 1;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						sample[0] <= Dout; //Begin shifting Dout into Sample
					end
					5'd7	:
					begin
						stateCounter <= stateCounter + 1;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						sample[1] <= Dout; // Shift Dout into sample
					end
					5'd8	:
					begin
						stateCounter <= stateCounter + 1;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						sample[2] <= Dout; // Shift Dout into sample
					end
					5'd9	:
					begin
						stateCounter <= stateCounter + 1;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						sample[3] <= Dout; // Shift Dout into sample
					end
					5'd10	:
					begin
						stateCounter <= stateCounter + 1;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						sample[4] <= Dout; // Shift Dout into sample
					end
					5'd11	:
					begin
						stateCounter <= stateCounter + 1;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						sample[5] <= Dout; // Shift Dout into sample
					end
					5'd12	:
					begin
						stateCounter <= stateCounter + 1;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						sample[6] <= Dout; // Shift Dout into sample
					end
					5'd13	:
					begin
						stateCounter <= stateCounter + 1;
						CS <= 1'b0; // Stays low to run chip
						Din <= 1'b1; // Don't Care
						sample[7] <= Dout; // Shift Dout into sample
					end

					// Cutoff sample conversion
					5'd14	:
					begin
						stateCounter <= stateCounter + 1;
						CS <= 1'b1; // Goes high for at least 310 ns for shutdown time
						Din <= 1'b1; // Don't Care
						Sample_word <= sample;
					end
					5'd15	:
					begin
						//stateCounter <= stateCounter + 1;
						CS <= 1'b1; // Goes high for at least 310 ns for shutdown time
						Din <= 1'b1; // Don't Care
						stateCounter <= 5'd0;
					end

					default	: stateCounter <= 5'd0;
				endcase
			end	// End if/else block for resetting

	end


	// Create a 3.125 MHz signal
	always @ (posedge CLK_50MHz or negedge RESET)
	begin

		if (RESET == 0)
			begin
				CLKsample <= 0;
				timeCounter <= 5'd0;
			end
		else
			begin
				timeCounter <= timeCounter + 1;
				if (timeCounter == 5'd8)
				begin
					CLKsample <= !CLKsample;
					timeCounter <= 5'd0;
				end
			end // End if/else block for resetting
	end

endmodule