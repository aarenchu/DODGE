module dodge
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		LEDR,
		LEDG
	);

	input			CLOCK_50;				//	50 MHz
	input   [17:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;			//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	output [17:0] LEDR;
	output [6:0] LEDG;
	
	
	wire resetn;
	assign resetn = SW[17];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	wire cntwire, ld_xw, ld_yw, ld_cw, ldout_xw,ldout_yw,ldout_cw;

	assign LEDR[7:0] = x;
	assign LEDG[6:0] = y;
	
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
	datapath d0(
		.clk(CLOCK_50),
    	.resetn(resetn),
		.data_in(SW[6:0]),
		.clr_in(SW[9:7]),
		.ldout_x(ldout_xw),
		.ldout_y(ldout_yw),
		.ldout_c(ldout_cw), 
    	.ld_x(ld_xw),
		.ld_y(ld_yw),
		.ld_c(ld_cw), 
		.enable(cntwire),  
    	.x_result(x),
		.y_result(y),
		.c_result(colour),
		.ledr(LEDR[17:14])
	);

    // Instansiate FSM control
    FSM c0(
		.clk(CLOCK_50),
    	.resetn(resetn),
    	.go(SW[15]),
		.controlx(SW[16]),
		.plot_signal(writeEn),
		.cnt_signal(cntwire),
		.ld_x(ld_xw),
		.ld_y(ld_yw),
		.ld_c(ld_cw),
		.ldout_x(ldout_xw),
		.ldout_y(ldout_yw),
		.ldout_c(ldout_cw)
	);
    
endmodule

module FSM(
	input clk,
    input resetn,
    input go,
	 input controlx,
	output reg plot_signal, cnt_signal,
	output reg  ld_x, ld_y, ld_c, ldout_x, ldout_y, ldout_c
	);
	reg [5:0] current_state, next_state;
	
	//States
	localparam S_LOAD_X = 5'd0, S_LOAD_X_WAIT = 5'd1, S_LOAD_Y = 5'd2, S_LOAD_Y_WAIT = 5'd3, S_CYCLE_0 = 5'd4, S_CYCLE_1 = 5'd5;
	
	//State Table
	always@(*)
    begin: state_table 
            case (current_state)
                S_LOAD_X: next_state = controlx ? S_LOAD_X_WAIT : S_LOAD_X; // Loop in current state until value is input
                S_LOAD_X_WAIT: next_state = controlx ? S_LOAD_X_WAIT : S_LOAD_Y; // Loop in current state until go signal goes low
                S_LOAD_Y: next_state = go ? S_LOAD_Y_WAIT : S_LOAD_Y; // Loop in current state until value is input
                S_LOAD_Y_WAIT: next_state = go ? S_LOAD_Y_WAIT : S_CYCLE_0; // Loop in current state until go signal goes low
                S_CYCLE_0: next_state = S_CYCLE_1; 
				S_CYCLE_1: next_state = S_LOAD_X; // Done, start over
                
            default:     next_state = S_LOAD_X;
        endcase
    end // state_table

	// Output Logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
			ld_x = 1'b0;
			ld_y = 1'b0;
			ld_c = 1'b0;
			ldout_x = 1'b0;
			ldout_y = 1'b0;
			ldout_c = 1'b0;

        case (current_state)
            S_LOAD_X: begin
                ld_x = 1'b1;
                end
            S_LOAD_Y: begin
                ld_y = 1'b1;
				ld_c = 1'b1;
                end
            S_CYCLE_0: begin 
                ldout_x= 1'b1; 
                ldout_y = 1'b1; 
                ldout_c = 1'b1;
            	end
			S_CYCLE_1: begin 
                plot_signal = 1'b1; //to vga
				cnt_signal = 1'b1; //to datapath
            end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals

	//Current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD_X;
        else
            current_state <= next_state;
    end // state_FFS
endmodule

module datapath(
	input clk,
    input resetn,
    input [6:0] data_in,
	input [2:0] clr_in,
    input ldout_x, ldout_y, ldout_c, 
    input ld_x, ld_y, ld_c, 
	input enable,  //for counter
    output reg [7:0] x_result,
	output reg [6:0] y_result,
	output reg [2:0] c_result,
	output [3:0] ledr
	);
	// input registers
    reg [7:0] x;
	reg [6:0] y;
	reg [2:0] c;

	wire [3:0] counter;

	// Input Logic
    always@(posedge clk) begin
        if(!resetn) begin
            x <= 8'b0; 
            y <= 7'b0; 
            c <= 3'b0; 
        end
        else begin
            if(ld_x)
                x <= data_in; // if ld_x is high load from data_in
            if(ld_y)
                y <= data_in; // if ld_y is high load from data_in
            if(ld_c)
                c <= clr_in; // if ld_c is high load from clr_in
        end
    end
	 
	// Counter
	counter c0(
		.reset(resetn),
		.clock(clk),
		.enable(enable),
		.q(counter)
	);
	
	// Output result
    always@(posedge clk) 
	 begin
        if(!resetn) 
				begin
					x_result <= 8'b0; 
					y_result <= 7'b0;
					c_result <= 3'b0;
				end
        else 
            if(ldout_x)
            	x_result <= counter[1:0]; //add least sig bits to x
				if(ldout_y)
					y_result <= counter[3:2]; //add most sig bits to y
				c_result <= c;
    end
endmodule

module twobit_counter(

	input reset,
	input clock,
	input enable,
	output reg [1:0] q);
	
	always @(posedge clock) // triggered every time clock rises
	begin
		if (!reset)
			q <= 0; // set q to 0
		else if (q == 2'b11) // ...otherwise if q is the maximum counter value
			q <= 0; // reset q to 0
		else if (enable == 1'b1) // ...otherwise update q (only when Enable is 1)
			q <= q + 1'b1; // increment q	
end
endmodule

module counter (clock, reset, enable, q);
	input reset;
	input clock;
	input enable;
	output reg [3:0] q;
	always @(posedge clock) // triggered every time clock rises
	begin
		if (!reset)
			q <= 0; // set q to 0
		else if (q == 4'b1111) // ...otherwise if q is the maximum counter value
			q <= 0; // reset q to 0
		else if (enable == 1'b1) // ...otherwise update q (only when Enable is 1)
			q <= q + 1'b1; // increment q	
end
endmodule