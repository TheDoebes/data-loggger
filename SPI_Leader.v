module SPI_Leader(CLK_50MHz, CLKsample, Din, Dout, CS, RESET, Sample_word);
	
	// SPI_Leader - control module for MCP3002 ADC
	
	// I/O - Labels corrospond to MCP3002 Datasheet
	input CLK_50MHz;
	input Dout;
	input RESET;
	output reg CLKsample;
	output reg Din;
	output reg CS;
	output reg [7:0] Sample_word;
	
	// Internal Wiring
	reg [4:0] timeCounter;	// 50MHz Counter, resets at 3.125 MHz
	reg [4:0] stateCounter; // 3.125 MHz counter, resets at every sample
	reg [7:0] sample;		// Shift register to deserialize sample bits
	
	// Logic
	
	// Interface with the device
	always @ (*)
	begin
		if (RESET)
		begin
			stateCounter <= 5'd15;
		end
				
		case (stateCounter) // Manipulate the control lines each clock cycle
			// Startup segment
			5'd0	: 
			begin
				stateCounter = stateCounter + 1;
				CS <= 1'b1;
				Din <= 1'b1; // Don't care
			end
			
			// Config segment
			5'd1	:
			begin
				stateCounter = stateCounter + 1;
				CS <= 1'b0; // Must be kept low for at least 100ns before next CLKsample
				Din <= 1'b1; // Startup condition
			end
			5'd2	:
			begin
				stateCounter = stateCounter + 1;
				CS <= 1'b0; // Stays low to run chip
				Din <= 1'b1; // Selects SIGNULAR mode
			end
			5'd3	:
			begin
				stateCounter = stateCounter + 1;
				CS <= 1'b0; // Stays low to run chip
				Din <= 1'b1; // Selects CH1 for analog input
			end
			5'd4	:
			begin
				stateCounter = stateCounter + 1;
				CS <= 1'b0; // Stays low to run chip
				Din <= 1'b1; // Selects MSB first mode
			end
			
			// Begin reading sample bit
			5'd5	:
			begin
				stateCounter = stateCounter + 1;
				CS <= 1'b0; // Stays low to run chip
				Din <= 1'b1; // Don't Care
				// Dout is null here
			end
			5'd6	:
			begin
				stateCounter = stateCounter + 1;
				CS <= 1'b0; // Stays low to run chip
				Din <= 1'b1; // Don't Care
				sample[0] <= Dout; //Begin shifting Dout into Sample
			end
			5'd7	:
			begin
				stateCounter = stateCounter + 1;
				CS <= 1'b0; // Stays low to run chip
				Din <= 1'b1; // Don't Care
				sample[1] <= Dout; // Shift Dout into sample
			end
			5'd8	:
			begin
				stateCounter = stateCounter + 1;
				CS <= 1'b0; // Stays low to run chip
				Din <= 1'b1; // Don't Care
				sample[2] <= Dout; // Shift Dout into sample
			end
			5'd9	:
			begin
				stateCounter = stateCounter + 1;
				CS <= 1'b0; // Stays low to run chip
				Din <= 1'b1; // Don't Care
				sample[3] <= Dout; // Shift Dout into sample
			end
			5'd10	:
			begin
				stateCounter = stateCounter + 1;
				CS <= 1'b0; // Stays low to run chip
				Din <= 1'b1; // Don't Care
				sample[4] <= Dout; // Shift Dout into sample
			end
			5'd11	:
			begin
				stateCounter = stateCounter + 1;
				CS <= 1'b0; // Stays low to run chip
				Din <= 1'b1; // Don't Care
				sample[5] <= Dout; // Shift Dout into sample
			end
			5'd12	:
			begin
				stateCounter = stateCounter + 1;
				CS <= 1'b0; // Stays low to run chip
				Din <= 1'b1; // Don't Care
				sample[6] <= Dout; // Shift Dout into sample
			end
			5'd13	:
			begin
				stateCounter = stateCounter + 1;
				CS <= 1'b0; // Stays low to run chip
				Din <= 1'b1; // Don't Care
				sample[7] <= Dout; // Shift Dout into sample
			end
			
			// Cutoff sample conversion
			5'd14	:
			begin
				stateCounter = stateCounter + 1;
				CS <= 1'b0; // Goes high for at least 310 ns for shutdown time
				Din <= 1'b1; // Don't Care
				Sample_word <= sample;
			end
			5'd15	:
			begin
				stateCounter = stateCounter + 1;
				CS <= 1'b0; // Goes high for at least 310 ns for shutdown time
				Din <= 1'b1; // Don't Care
				stateCounter <= 5'd0;
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