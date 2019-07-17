module game
	(
		CLOCK_50,						//	On Board 50 MHz
		SW,
        KEY,
		// VGA OUTPUT
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,					//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		LEDR
	);

    // BOARD INPUT 
	input CLOCK_50;				    //	50 MHz
	input [3:0] KEY;
	input [17:0] SW;

	// VGA OUTPUT
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;			//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output [9:0]	VGA_R;   				//	VGA Red[9:0]
	output [9:0]	VGA_G;	 				//	VGA Green[9:0]
	output [9:0]	VGA_B;   				//	VGA Blue[9:0]
	output [7:0] LEDR;
	
	// VGA INSTANTIATION
	vga_adapter VGA(
			.resetn(1'b1),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1'b1),
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
		

  //**************************
  //* DATA STORAGE VARIABLES *
  //**************************
	// colour, x and y that will go into VGA for display
	reg [2:0] colour;
  reg [7:0] x;
  reg [6:0] y;

  assign LEDR[7:0] = x;
  // player object position and speed parameters
	reg [7:0] player_x;
	reg [6:0] player_y;
  reg player_speed;
  reg mv_left;
  reg mv_right;
  reg mv_up;
  reg mv_down;
  
  // counter for drawing 
  reg [17:0] counter;
  // reg [17:0] erase_counter;
    
  // current state indicator
  reg [5:0] current_state;

<<<<<<< HEAD
    
=======
>>>>>>> e291ff41617a48e92916b389e2db3cf53e6f9910
  
    //**********
    //* STATES *
    //**********
    localparam SET_X = 6'b000000,
					RESET = 6'b000001,
					LOAD_PLAYER = 6'b000010,
					WAIT= 6'b000011,
					ERASE_PLAYER = 6'b000100, 
               MOVE_PLAYER = 6'b000101,   
               DRAW_PLAYER = 6'b000110
               ;

    //************************
    //* STATES CONTROL LOGIC *
    //************************


    // rate divider, delay before redraw
	wire frame;
	clock(.clock(CLOCK_50), .clk(frame));
<<<<<<< HEAD
	
    //State Table
	always@(*)
    begin: state_table 
        case (current_state)
            LOAD_PLAYER: next_state = ~SW[17] ? LOAD_PLAYER : WAIT; // Loop in current state until value is input
            WAIT: next_state = s1 ? WAIT : ERASE_PLAYER; // Loop in current state until go signal goes low
            ERASE_PLAYER: next_state = s2 ? ERASE_PLAYER : MOVE_PLAYER; // Loop in current state until value is input
            MOVE_PLAYER: next_state = s3 ? MOVE_PLAYER : DRAW_PLAYER; // Loop in current state until go signal goes low
            DRAW_PLAYER: next_state = s4 ? DRAW_PLAYER : MOVE_PLAYER;  // Draw
        default: next_state = LOAD_PLAYER;
        endcase
    end // state_table

	always @(*)
    begin: enable_signals
=======

	 
	 always @(posedge CLOCK_50)
    begin
>>>>>>> e291ff41617a48e92916b389e2db3cf53e6f9910
        // Initialize values 
			colour = 3'b000;
            x = 7'b0000000;
            y = 6'b000000;
        
		if (~KEY[2])
			current_state = RESET;
      case (current_state)
				
				RESET: begin
				if (counter < 17'b10000000000000000) begin
						x = counter[7:0];
						y = counter[16:8];
						counter = counter + 1'b1;
						end
					else begin
						counter= 8'b00000000;
						current_state = LOAD_PLAYER;
					end
end
            LOAD_PLAYER: begin
            if (counter < 8'b00010000) begin 
            // set original position of the player and draw using counter
					player_x = 8'd80;
                player_y = 7'd50;
                colour = 3'b010;
                player_speed = 1'b1;
                x = player_x + counter [1:0];
                y = player_y + counter [3:2];
                counter = counter + 1'b1;
                end 
            else begin
                counter = 18'b0;
                current_state = WAIT;
                end
            end
            
				WAIT: begin
				// wait a frame
				if (frame)
					current_state = ERASE_PLAYER;
				end
				
            ERASE_PLAYER: begin
				if (counter < 8'b00010000) begin 
	                colour = 3'b000;
	                x = player_x + counter [1:0];
	                y = player_y + counter [3:2];
	                counter = counter + 1'b1;
                end 
				else begin
                counter = 18'b0;
                current_state = MOVE_PLAYER;
                end
            end

            MOVE_PLAYER: begin 
            // update position of the player if needed (i.e. based on key input)
            // key 0-left 1-right 2-up 3-down
            if (~KEY[0] && player_x > 8'd10) begin
                player_x = player_x - player_speed;
                end
            if (~KEY[1] && player_x < 8'd150) begin
                player_x = player_x + player_speed;
                end   
            // if (~KEY[2] && player_y > 7'd10) begin
                // player_y = player_y - player_speed;
                // end   
            if (~KEY[3] && player_y < 7'd110) begin
                player_y = player_y + player_speed;
                end
            current_state = DRAW_PLAYER;
            end
            
            DRAW_PLAYER: begin 
            if (counter < 8'b00010000) begin 
            // draw the player using counter
                x = player_x + counter [1:0];
                y = player_y + counter [3:2];
                counter = counter + 1'b1;
                end 
            else begin
                counter = 18'b0;
                current_state = MOVE_PLAYER;
                end
			end
        endcase
    end
<<<<<<< HEAD
    
    always@(posedge CLOCK_50)
    begin: state_FFs
        if(!SW[17])
            current_state <= LOAD_PLAYER;
        else
            current_state <= next_state;
    end // state_FFS

=======
>>>>>>> e291ff41617a48e92916b389e2db3cf53e6f9910
endmodule

// module counts a number of clock ticks to simulate 60 frames per second
// send go signal each frame counted
module clock(input clock, output clk);
reg [19:0] frame_counter;
reg frame;
	always@(posedge clock)
    begin
        if (frame_counter == 20'b00000000000000000000) begin
		  frame_counter = 20'b11001011011100110100;
		  frame = 1'b1;
		  end
        else begin
			frame_counter = frame_counter - 1'b1;
			frame = 1'b0;
		  end
    end
	 assign clk = frame;
endmodule
