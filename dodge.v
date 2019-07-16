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
	wire isDone;
	wire ld_xw, ld_yw, ld_cw, ld_alu_out, alu_op;

	
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
			.plot(out),
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
    	.ld_x(ld_xw),
		.ld_y(ld_yw),
		.ld_c(ld_cw),
		.out(out),
		.alu_op(alu_op),
		.ld_alu_out(ld_alu_out),
    	.x_result(x),
		.y_result(y),
		.c_result(colour),
		.done(isDone)
	);

    // Instansiate FSM control
    FSM f0(
		.clk(CLOCK_50),
    	.resetn(resetn),
    	.go(SW[15]),
		.controlx(SW[16]),
		.done(isDone),
		.ld_x(ld_xw),
		.ld_y(ld_yw),
		.ld_c(ld_cw), 
		.out(out),
		.alu_op(alu_op),
		.ld_alu_out(ld_alu_out)
	);
    
endmodule

module FSM(
	input clk,
    input resetn,
    input go,
	 input controlx,
	 input done,
	output reg  ld_x, ld_y, ld_c, out, alu_op, ld_alu_out
	);
	reg [5:0] current_state, next_state;
	
	//States
	localparam S_LOAD_X = 5'd0, S_LOAD_X_WAIT = 5'd1, S_LOAD_Y = 5'd2, S_LOAD_Y_WAIT = 5'd3, S_DRAW = 5'd4, S_COUNT = 5'd5;
	
	//State Table
	always@(*)
    begin: state_table 
            case (current_state)
                S_LOAD_X: next_state = controlx ? S_LOAD_X_WAIT : S_LOAD_X; // Loop in current state until value is input
                S_LOAD_X_WAIT: next_state = controlx ? S_LOAD_X_WAIT : S_LOAD_Y; // Loop in current state until go signal goes low
                S_LOAD_Y: next_state = go ? S_LOAD_Y_WAIT : S_LOAD_Y; // Loop in current state until value is input
                S_LOAD_Y_WAIT: next_state = go ? S_LOAD_Y_WAIT : S_DRAW; // Loop in current state until go signal goes low
                S_DRAW: next_state = S_COUNT; // Draw
					 S_COUNT: next_state = done ? S_LOAD_X : S_DRAW; // Count until counter is done
                
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
			out = 1'b0;
			alu_op = 1'b0;
			ld_alu_out = 1'b0;

        case (current_state)
            S_LOAD_X: begin
                ld_x = 1'b1;
					 ld_alu_out = 1'b0;
					 out = 1'b0;
					 alu_op = 1'b0;
                end
            S_LOAD_Y: begin
					 ld_alu_out = 1'b0;
                ld_y = 1'b1;
					 ld_c = 1'b1;
					 out = 1'b0;
					 alu_op = 1'b0;
                end
            S_DRAW: begin 
                out = 1'b1;
					 alu_op = 1'b0;
					 ld_alu_out = 1'b0;
            	end
				S_COUNT: begin 
                out = 1'b0;
					 alu_op = 1'b1;
					 ld_alu_out = 1'b1;
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
    input ld_x, ld_y, ld_c, out, alu_op, ld_alu_out, // signals from FSM 
    output reg [7:0] x_result,
	 output reg [6:0] y_result,
	 output reg [2:0] c_result,
	 output done
	);
	// input registers
   reg [7:0] x;
	reg [6:0] y;
	reg [2:0] c;

	wire [3:0] counter;
	
	// output of the ALU
	reg [7:0] x_alu_out;
	reg [6:0] y_alu_out;
	
	// Input Logic
    always@(posedge clk) begin
        if(!resetn) begin
            x <= 8'b0; 
            y <= 7'b0; 
            c <= 3'b0; 
        end
        else begin
            if(ld_x)
                x <= ld_alu_out ? x_alu_out : {1'b0, data_in}; // if ld_x is high load from alu if ld_alu_out is high
            if(ld_y)
                y <= ld_alu_out ? y_alu_out: data_in; // if ld_y is high load from alu if ld_alu_out is high
            if(ld_c)
                c <= clr_in; // if ld_c is high load from clr_in
        end
    end
	 
	// Counter
	counter c0(
		.reset(resetn),
		.clock(clk),
		.enable(alu_op),
		.q(counter),
		.done(done)
	);
	
	// ALU
	always @(*)
    begin : ALU
          x_alu_out = counter[1:0];
		  y_alu_out = counter[3:2];
    end
	
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
            if(out)begin
            		x_result <= x; // reset to og values
            		y_result <= y;
            	    x_result <= x + x_alu_out; //add least sig bits to x
					y_result <= y + y_alu_out; //add most sig bits to y
				end
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

module counter (clock, reset, enable, q, done);
	input reset;
	input clock;
	input enable;
	output reg [3:0] q;
	output reg done;
	always @(posedge clock) // triggered every time clock rises
	begin
		if (!reset) begin
			q <= 0; // set q to 0
			done <= 1'b0;
			end
		else if (q == 4'b1111) begin // ...otherwise if q is the maximum counter value
			q <= 0; // reset q to 0
			done <= 1'b1;
			end
		else if (enable == 1'b1) begin // ...otherwise update q (only when Enable is 1)
			q <= q + 1'b1; // increment q
			done <= 1'b0;
			end
	end
endmodule