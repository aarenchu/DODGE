module dodge(
	
	CLOCK_50,						//	On Board 50 MHz
	// Your inputs and outputs here
    KEY,
    SW,
	// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,					//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn, ctrl_x, ctrl_y, ctrl_c;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
    // Instansiate datapath
	datapath d0(SW[6:0], SW[9:7] , CLOCK_50, KEY[0], x, y, colour, ctrl_x, ctrl_y, ctrl_c);

	// Instansiate FSM control
	control c0(CLOCK_50, KEY[0], KEY[3], ctrl_x, ctrl_y, ctrl_c, writeEn);

	// initialization of keyboard controller
	wire [3:0] player_keycontrol;
    wire [7:0] kb_scan_code;
	wire kb_sc_ready, kb_letter_case;
	key2ascii SC2A (
		.letter_case(kb_letter_case),
		.scan_code(kb_scan_code),
		.player_keycontrol(player_keycontrol)
	);
	keyboard kd (
		.clk(CLOCK_50),
		.reset(~resetn),
		.ps2d(PS2_KBDAT),
		.ps2c(PS2_KBCLK),
		.scan_code(kb_scan_code),
		.scan_code_ready(kb_sc_ready),
		.letter_case_out(kb_letter_case)
);
   
endmodule



module control(clk, ResetN, go, writeEn, ctrl_x, ctrl_y, ctrl_c);
	input clk, ResetN, go;
	output reg writeEn, ctrl_x, ctrl_y, ctrl_c;
	
    reg [6:0] current_state, next_state; 
    
    localparam  S_LOAD_X        = 5'd0,
                S_LOAD_X_WAIT   = 5'd1,
                S_LOAD_Y        = 5'd2,
                S_LOAD_Y_WAIT   = 5'd3,
                S_LOAD_C        = 5'd4,
                S_LOAD_C_WAIT   = 5'd5,
                Plot      = 5'd6;
    
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
                S_LOAD_X: next_state = go ? S_LOAD_X_WAIT : S_LOAD_X; // Loop in current state until value is input
                S_LOAD_X_WAIT: next_state = go ? S_LOAD_X_WAIT : S_LOAD_Y; // Loop in current state until go signal goes low
                S_LOAD_Y: next_state = go ? S_LOAD_Y_WAIT : S_LOAD_Y; // Loop in current state until value is input
                S_LOAD_Y_WAIT: next_state = go ? S_LOAD_Y_WAIT : S_LOAD_C; // Loop in current state until go signal goes low
                S_LOAD_C: next_state = go ? S_LOAD_C_WAIT : S_LOAD_C; // Loop in current state until value is input
                S_LOAD_C_WAIT: next_state = go ? PLOT : S_LOAD_C_WAIT; // Loop in current state until go signal goes low
                Plot: next_state = go ? S_LOAD_X : Plot; // Loop in current state until value is input
                default:     next_state = S_LOAD_X;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        ctrl_x = 1'b0;
        ctrl_y = 1'b0;
        ctrl_c = 1'b0;
        writeEn = 1'b0;

        case (current_state)
            S_LOAD_X: begin
                ctrl_x = 1'b1;
                end
            S_LOAD_Y: begin
                ctrl_y = 1'b1;
                end
            S_LOAD_C: begin
                ctrl_c = 1'b1;
                end
            PLOT: begin
                writeEn = 1'b1;
                end
        // default:    
        // dont need default since all of outputs assigned a value at the start of the always block
        endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD_X;
        else
            current_state <= next_state;
    end // state_FFS
endmodule


module datapath(data_in, colour, clk, ResetN, x, y , c, ctrl_x, ctrl_y, ctrl_c);
	input [6:0] data_in;
	input [2:0] color;
	input clk, ResetN, ctrl_x, ctrl_y, ctrl_c;
	output reg x, y, c, 
		
		// input registers
	reg [7:0] a;
	reg [6:0] b;
	reg [2:0] d;


	// Registers a, b, c, x with respective input logic
	always@(posedge clk) begin
		if(!ResetN) begin
			a <= 7'b0; 
			b <= 6'b0; 
			d <= 3'b0; 
		end
		else begin
			if(ctrl_x)
				x <= {1'b0, data_in};
			if(ctrl_y)
				y <= data_in;
			if(ctrl_c)
				c <= colour
		end
	end
 
	// Output result register
	always@(posedge clk) begin
			if(!resetN) begin
				a <= 7'b0;
				b <= 6'b0;
				d <= 3'b0;  
			end
			else 
				a <= x;
				b <= y;
				d <= c;
	end
 
	reg [3:0] q;
	always @(posedge clk) // triggered every time clock rises
	begin
		if (ResetN == 1'b1) // when Clear b is 1
			q <= 4'b0000; // q is set to 0
		else if (q == 4'b1111) // when q is the maximum value for the counter
			q <= 0; // q reset to 0
		else // increment q
			q <= q + 1'b1; // increment q
			x <= x + q[1:0];
			y <= y + q[3:2];
	end



endmodule