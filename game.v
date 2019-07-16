module game
	(
		CLOCK_50,						//	On Board 50 MHz
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
	);

    // BOARD INPUT 
	input CLOCK_50;				    //	50 MHz
	input [3:0] KEY;

	// VGA OUTPUT
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;			//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output [9:0]	VGA_R;   				//	VGA Red[9:0]
	output [9:0]	VGA_G;	 				//	VGA Green[9:0]
	output [9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	// VGA INSTANTIATION
	vga_adapter VGA(
			.resetn(1'b1),
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
			

  //**************************
  //* DATA STORAGE VARIABLES *
  //**************************
	// colour, x and y that will go into VGA for display
	reg [2:0] colour;
  reg [7:0] x;
  reg [6:0] y;

  // player object position and speed parameters
	reg [7:0] player_x;
	reg [6:0] player_y;
  reg [2:0] player_speed;
  reg mv_left;
  reg mv_right;
  reg mv_up;
  reg mv_down;
  
  // counter for drawing 
  reg [17:0] counter;
    
  // current state indicator
  reg [5:0] current_state;

    //**********
    //* STATES *
    //**********
    localparam LOAD_PLAYER = 5'd0, 
               MOVE_PLAYER = 5'd1,   
               DRAW_PLAYER = 5'd2;

    //************************
    //* STATES CONTROL LOGIC *
    //************************

    always @(posedge CLOCK_50)
    begin
        // Initialize values 
			colour = 3'b000;
            x = 7'b0000000;
            y = 6'b000000;
        
        case (current_state)
            LOAD_PLAYER: begin
            if (counter < 8'b10000000) begin 
            // set original position of the player and draw using counter
                player_x = 8'd80;
                player_y = 7'd50;
                colour = 3'b010;
                player_speed = 1'b1;
                x = player_x + counter [3:0];
                y = player_y + counter [7:4];
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
            // ERASE PLAYER ?
            assign mv_left = ~KEY[0];
            assign mv_right= ~KEY[1];
            assign mv_up = ~KEY[2];
            assign mv_down = ~KEY[3];
            if (mv_left && player_x > 8'd10) begin
                player_x = player_x - player_speed;
                end
            if (mv_right && player_x < 8'd150) begin
                player_x = player_x + player_speed;
                end   
            if (mv_up && player_y > 7'd10) begin
                player_y = player_y - player_speed;
                end   
            if (mv_down && player_y < 7'd110) begin
                player_y = player_y + player_speed;
                end   
            current_state = DRAW_PLAYER;
            end
            
            DRAW_PLAYER: begin 
            if (counter < 8'b10000000) begin 
            // draw the player using counter
                x = player_x + counter [3:0];
                y = player_y + counter [7:4];
                counter = counter + 1'b1;
                end 
            else begin
                counter = 18'b0;
                current_state = MOVE_PLAYER;
                end
			      end
        endcase
    end
endmodule
