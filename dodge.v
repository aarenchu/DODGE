module dodge(CLOCK_50,
					SW,
					KEY,
					HEX0,
					HEX1,
					HEX2,
					LEDR,
					// The parts below are for the VGA output.  Do not change.
					VGA_CLK,   						//	VGA Clock
					VGA_HS,							//	VGA H_SYNC
					VGA_VS,							//	VGA V_SYNC
					VGA_BLANK_N,						//	VGA BLANK
					VGA_SYNC_N,						//	VGA SYNC
					VGA_R,   						//	VGA Red[9:0]
					VGA_G,	 						//	VGA Green[9:0]
					VGA_B					//	VGA Blue[9:0]
		);
	// Based off of Space Invaders by Matthew Chau and Zixiong Lin
	// KEY[0] moves right
	// KEY[1] moves down
	// KEY[2] moves up
	// KEY[3] moves leftt
	// SW[17] turn on game
	
	input CLOCK_50;
	// used for control
	input [17:0] SW;
	input [3:0] KEY;
	
	// outputs Hex (for score)
	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX2;

	
	// output for debugging
	output [17:0] LEDR;
	
	// outputs for VGA
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	// Create the colour, x, y wires that are inputs to the controller.
	reg [2:0] colour;
	reg [7:0] x;
	reg [7:0] y;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
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
	
	// coordinates for player, bases, and enemy
	reg [7:0] p_x;
	reg [7:0] p_y;
	
	reg [7:0] A_enemy_x;
	reg [7:0] A_enemy_y;
	reg [7:0] A1_x;
	reg [7:0] A1_y;
	reg [7:0] A2_x;
	reg [7:0] A2_y;
	reg [7:0] A3_x;
	reg [7:0] A3_y;
	reg [7:0] A4_x;
	reg [7:0] A4_y;
	// We added the following registers
	reg [7:0] B_enemy_x;
	reg [7:0] B_enemy_y;
	reg [7:0] B1_x;
	reg [7:0] B1_y;
	reg [7:0] B2_x;
	reg [7:0] B2_y;
	reg [7:0] B3_x;
	reg [7:0] B3_y;
	reg [7:0] B4_x;
	reg [7:0] B4_y;
	reg [7:0] C_enemy_x;
	reg [7:0] C_enemy_y;
	reg [7:0] C1_x;
	reg [7:0] C1_y;
	reg [7:0] C2_x;
	reg [7:0] C2_y;
	reg [7:0] D_enemy_x;
	reg [7:0] D_enemy_y;
	reg [7:0] D1_x;
	reg [7:0] D1_y;
	reg [7:0] D2_x;
	reg [7:0] D2_y;

	
	// track if bases are active (1 for active, 0 for inactive) C1,C2 active starting level 2, D1, D2 active starting level 3
	reg A1;
	reg A2;
	reg A3;
	reg A4;
	// we added the following registers
	reg B1;
	reg B2;
	reg B3;
	reg B4;
	reg C1;
	reg C2;
	reg D1;
	reg D2;
	
	
	
	// track current state
	reg [6:0] current_state;
	// counter for drawing
	reg [17:0] draw_count;
	// keep track of direction of bases 
	reg a1_right;
	reg a2_right;
	reg a3_right;
	reg a4_right;
	// we added the following registers
	reg b1_right;
	reg b2_right;
	reg b3_right;
	reg b4_right;
	reg c1_down;
	reg c2_down;
	reg d1_down;
	reg d2_down;

	// keep track of direction of enemies
	reg A_enemy_up;
	// we added the following registers
	reg B_enemy_up;
	reg C_enemy_right;
	reg D_enemy_right;
	
	// keep track of level up dependent on timer. Increase level every 10s. (we added this wire)
	wire [1:0] lvl_up;

	// timer/score on HEX0, HEX1, HEX2 (we added this from FlappyBox by Alex Wong et al.
	reg collided;
    wire [3:0] current_time_wire;
	 
	clock time_last(
        .CLOCK_50(CLOCK_50),
        .clk_speed(3'd1),
        .current_number(current_time_wire),
        .collided(collided),
        .key_press(~SW[17])
        );

	time_counter current_time(
        .binary_time(current_time_wire),
        .CLOCK_50(CLOCK_50),
        .hex_0(HEX0),
        .hex_1(HEX1),
        .hex_2(HEX2),
        .collided(collided),
        .key_press(~SW[17]),
		  .ledr(LEDR[1:0]),
		  .lvl(lvl_up)
        );
		  

	
	/***************************************
	FSM and datapath begins
	****************************************/
	localparam  RESET 			= 7'd30,
				INIT_PLAYER 	= 7'd1,
				INIT_A1 		= 7'd3,
				INIT_A2 		= 7'd17,
				INIT_A3 		= 7'd18,
				INIT_A4 		= 7'd19,
				WAIT			= 7'd4,

				ERASE_PLAYER 	= 7'd5,
				UPDATE_PLAYER 	= 7'd6,
				DRAW_PLAYER 	= 7'd7,

				ERASE_A1 		= 7'd11,
				UPDATE_A1 		= 7'd12,
				DRAW_A1			= 7'd13,
				ERASE_A2 		= 7'd20,
				UPDATE_A2 		= 7'd21,
				DRAW_A2			= 7'd22,
				ERASE_A3 		= 7'd23,
				UPDATE_A3 		= 7'd24,
				DRAW_A3			= 7'd25,
				ERASE_A4 		= 7'd26,
				UPDATE_A4 		= 7'd27,
				DRAW_A4			= 7'd28,

				DEATH			= 7'd14,


				INIT_A_ENEMY 		= 7'd35,
				ERASE_A_ENEMY 		= 7'd36,
				UPDATE_A_ENEMY 		= 7'd37,
				DRAW_A_ENEMY 		= 7'd38,
				TEST_A_HIT 			= 7'd39,
				// we added the rest of these states
				INIT_B1 			= 7'd8,
				INIT_B2 			= 7'd9,
				INIT_B3 			= 7'd10,
				INIT_B4 			= 7'd15,
				INIT_B_ENEMY 		= 7'd40,
				ERASE_B_ENEMY 		= 7'd41,
				UPDATE_B_ENEMY 		= 7'd42,
				DRAW_B_ENEMY 		= 7'd43,
				TEST_B_HIT 			= 7'd44,
				ERASE_B1 			= 7'd45,
				UPDATE_B1 			= 7'd46,
				DRAW_B1				= 7'd47,
				ERASE_B2 			= 7'd48,
				UPDATE_B2 			= 7'd49,
				DRAW_B2				= 7'd50,
				ERASE_B3 			= 7'd51,
				UPDATE_B3 			= 7'd52,
				DRAW_B3				= 7'd53,
				ERASE_B4 			= 7'd54,
				UPDATE_B4 			= 7'd55,
				DRAW_B4				= 7'd56,
				INIT_C1 			= 7'd57,
				INIT_C2 			= 7'd58,
				INIT_D1 			= 7'd59,
				INIT_D2 			= 7'd60,
				INIT_C_ENEMY 		= 7'd61,
				ERASE_C_ENEMY 		= 7'd62,
				UPDATE_C_ENEMY 		= 7'd63,
				DRAW_C_ENEMY 		= 7'd64,
				TEST_C_HIT 			= 7'd65,
				ERASE_C1 			= 7'd66,
				UPDATE_C1 			= 7'd67,
				DRAW_C1				= 7'd68,
				ERASE_C2 			= 7'd69,
				UPDATE_C2 			= 7'd70,
				DRAW_C2				= 7'd71,
				ERASE_D1 			= 7'd72,
				UPDATE_D1 			= 7'd73,
				DRAW_D1				= 7'd74,
				ERASE_D2 			= 7'd75,
				UPDATE_D2 			= 7'd76,
				DRAW_D2				= 7'd77,
				INIT_D_ENEMY 		= 7'd79,
				ERASE_D_ENEMY		= 7'd80,
				UPDATE_D_ENEMY 		= 7'd81,
				DRAW_D_ENEMY 		= 7'd82,
				TEST_D_HIT 			= 7'd83;
	
	// for WAIT, delay before redrawing
	wire frame;
	frame_counter(.clock(CLOCK_50), .go(frame));
	
	always @(posedge CLOCK_50)
	begin
		// set initial values
		colour = 3'b000;
		x = 8'b00000000;
		y = 8'b00000000;
		
		// turn on game, we switched the reset to a switch
		if (~SW[17])
			current_state = RESET;
	
		
		case(current_state)
			RESET: begin
				collided = 1'b0;
				// reset the screen by making it all black
				if (draw_count < 17'b1000_0000_0000_0000_0) begin
					x = draw_count[7:0];
					y = draw_count[15:8];
					draw_count = draw_count + 1'b1;
					end
				else begin
					draw_count= 18'b0;
					current_state = INIT_PLAYER;
					end
				end
			INIT_PLAYER: begin
				// initialize the player
				if (draw_count < 8'b1000_0000) begin
					p_x = 8'd76;
					p_y = 8'd58;
					x = p_x + draw_count[1:0];
					y = p_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b111;
					end
				else begin
					draw_count= 18'b0;
					current_state = INIT_A1;
					end
				end
			
			/* Initialize top bases and enemy */
			INIT_A1: begin
				if (draw_count < 8'b1000_0000) begin
					A1_x = 8'd0;
					A1_y = 8'd0;
					x = A1_x + draw_count[1:0];
					y = A1_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					// start bases moving right
					a1_right = 1'b1;
					A1 = 1'b1;
					end
				else begin
					draw_count= 18'b0;
					current_state = INIT_A_ENEMY;
					end
				end
			INIT_A_ENEMY: begin
				// initialize the top enemy
				A_enemy_x = 8'd8;
				A_enemy_y = 8'd9;
				A_enemy_up = 1'b0;	
				if (draw_count < 8'b1000_0000) begin
					x = A_enemy_x+ draw_count[1:0];
					y = A_enemy_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b100;
					end
				else begin
					draw_count= 18'b0;
						current_state = INIT_A2;
					end
			end
			INIT_A2: begin
				if (draw_count < 8'b1000_0000) begin
					A2_x = 8'd30;
					A2_y = 8'd0;
					x = A2_x + draw_count[1:0];
					y = A2_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					// start bases moving right
					a2_right = 1'b1;
					A2 = 1'b1;
					end
				else begin
					draw_count= 18'b0;
					current_state = INIT_A3;
					end
				end
			INIT_A3: begin
				if (draw_count < 8'b1000_0000) begin
					A3_x = 8'd60;
					A3_y = 8'd0;
					x = A3_x + draw_count[1:0];
					y = A3_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					// start bases moving right
					a3_right = 1'b1;
					A3 = 1'b1;
					end
				else begin
					draw_count= 18'b0;
					current_state = INIT_A4;
				end
				end
			INIT_A4: begin
				if (draw_count < 8'b1000_0000) begin
					A4_x = 8'd90;
					A4_y = 8'd0;
					x = A4_x + draw_count[1:0];
					y = A4_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					// start bases moving right
					a4_right = 1'b1;
					A4 = 1'b1;
					end
				else begin
					draw_count= 18'b0;
					current_state = INIT_B1;
					end
				end
			/* Initialize bottom bases and enemies, we added these states */
			INIT_B1: begin
				if (draw_count < 8'b1000_0000) begin
					B1_x = 8'd0;
					B1_y = 8'd111;
					x = B1_x + draw_count[1:0];
					y = B1_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					// start bases moving right
					b1_right = 1'b1;
					B1 = 1'b1;
					end
				else begin
					draw_count= 18'b0;
					current_state = INIT_B_ENEMY;
					end
				end
			INIT_B_ENEMY: begin
				// initialize the enemy
				B_enemy_x = 8'd8;
				B_enemy_y = 8'd9;
				B_enemy_up = 1'b0;	
				if (draw_count < 8'b1000_0000) begin
					x = B_enemy_x+ draw_count[1:0];
					y = B_enemy_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b100;
					end
				else begin
					draw_count= 18'b0;
					current_state = INIT_B2;
					end
				end
			INIT_B2: begin
				if (draw_count < 8'b1000_0000) begin
					B2_x = 8'd30;
					B2_y = 8'd111;
					x = B2_x + draw_count[1:0];
					y = B2_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					// start bases moving right
					b2_right = 1'b1;
					B2 = 1'b1;
					end
				else begin
					draw_count= 18'b0;
					current_state = INIT_B3;
					end
				end
			INIT_B3: begin
				if (draw_count < 8'b1000_0000) begin
					B3_x = 8'd60;
					B3_y = 8'd111;
					x = B3_x + draw_count[1:0];
					y = B3_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					// start bases moving right
					b3_right = 1'b1;
					B3 = 1'b1;
					end
				else begin
					draw_count= 18'b0;
					current_state = INIT_B4;
				end
				end
			INIT_B4: begin
				if (draw_count < 8'b1000_0000) begin
					B4_x = 8'd90;
					B4_y = 8'd111;
					x = B4_x + draw_count[1:0];
					y = B4_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					// start bases moving right
					b4_right = 1'b1;
					B4 = 1'b1;
					end
				else begin
					draw_count= 18'b0;
					current_state = INIT_C1;
					end
				end
			/* Initialize left bases even though they don't start appearing until lvl 2, we added these states */
			INIT_C1: begin
				if (draw_count < 8'b1000_0000) begin
					C1_x = 8'd0;
					C1_y = 8'd30;
					x = C1_x + draw_count[1:0];
					y = C1_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					// start bases moving down
					c1_down = 1'b1;
					C1 = 1'b1;
					end
				else begin
					draw_count= 18'b0;
					current_state = INIT_C_ENEMY;
					end
				end
			INIT_C_ENEMY: begin
				// initialize the left enemy
				C_enemy_x = 8'd9;
				C_enemy_y = 8'd8;
				C_enemy_right = 1'b1;	
				if (draw_count < 8'b1000_0000) begin
					x = C_enemy_x+ draw_count[1:0];
					y = C_enemy_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = INIT_C2;
					end
				end
			INIT_C2: begin
				if (draw_count < 8'b1000_0000) begin
					C2_x = 8'd0;
					C2_y = 8'd60;
					x = C2_x + draw_count[1:0];
					y = C2_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					// start bases moving down
					c2_down = 1'b1;
					C2 = 1'b1;
					end
				else begin
					draw_count= 18'b0;
					current_state = INIT_D1;
					end
				end
			/* Initialize right bases even though they don't start appearing until lvl 3, we added these states */
			INIT_D1: begin
				if (draw_count < 8'b1000_0000) begin
					D1_x = 8'd150;
					D1_y = 8'd30;
					x = D1_x + draw_count[1:0];
					y = D1_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					// start bases moving down
					d1_down = 1'b1;
					D1 = 1'b1;
					end
				else begin
					draw_count= 18'b0;
					current_state = INIT_D_ENEMY;
					end
				end
			INIT_D_ENEMY: begin
				// initialize the right enemy
				D_enemy_x = 8'd140;
				D_enemy_y = 8'd8;
				D_enemy_right = 1'b0;
					
				if (draw_count < 8'b1000_0000) begin
					x = D_enemy_x+ draw_count[1:0];
					y = D_enemy_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = INIT_D2;
					end
				end
			INIT_D2: begin
				if (draw_count < 8'b1000_0000) begin
					D2_x = 8'd150;
					D2_y = 8'd60;
					x = D2_x + draw_count[1:0];
					y = D2_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					// start bases moving down
					d2_down = 1'b1;
					D2 = 1'b1;
					end
				else begin
					draw_count= 18'b0;
					current_state = WAIT;
					end
				end
			
			WAIT: begin
				// wait a frame
				if (frame)
					current_state = ERASE_PLAYER;
				end
				
			/* Main player states */
			ERASE_PLAYER: begin
				// erase the player from its previous location
				if (draw_count < 8'b1000_0000) begin
					x = p_x + draw_count[1:0];
					y = p_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_PLAYER;
					end
				end
			UPDATE_PLAYER: begin
				// update player's new position
				// make sure that player can't move further past set boundaries
				if (~KEY[0] && p_x < 8'd110) begin // right
					p_x = p_x + 1'b1;
					end
				if (~KEY[3] && p_x > 8'd30) begin // left
					p_x = p_x - 1'b1;
					end
				// we added the vertical movement
				if (~KEY[1] && p_y < 8'd90) begin // up
					p_y = p_y + 1'b1;
					end
				if (~KEY[2] && p_y > 8'd30) begin // down
					p_y = p_y - 1'b1;
					end
				current_state = DRAW_PLAYER;
				end
			DRAW_PLAYER: begin
				if (draw_count < 8'b1000_0000) begin
					x = p_x + draw_count[1:0];
					y = p_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b111;
					end					
				else begin
					draw_count= 18'b0;
					current_state = ERASE_A1;
					end
				end
			/* Main top base states */
			ERASE_A1: begin
				if (draw_count < 8'b1000_0000) begin
					x = A1_x + draw_count[1:0];
					y = A1_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_A1;
					end
				end
			UPDATE_A1: begin
					// update new  position
					// make sure that  can't move further past the left or right of the screen
					// check if reached edge of left and right
					if (A1_x >= 8'd144) begin
						a1_right = 1'b0;
						A1_x = 8'd144;
						end
					else if ((A1_x <= 8'd0) && (A1_y != 8'd0)) begin
						a1_right = 1'b1;
						A1_x = 8'd0;
						end
					
					// update x position
					if (a1_right == 1'b1) begin
						A1_x = A1_x + 1'b1;
						end
					else begin
						A1_x = A1_x - 1'b1;
						end
					
					
					if (A1 == 1'b1) begin
						// if base is active, draw it
						current_state = DRAW_A1;
					end
					else begin
						// base inactive, so erase
						current_state = ERASE_A2;
					end
				
				end
			DRAW_A1: begin
				if (draw_count < 8'b1000_0000) begin
					x = A1_x + draw_count[1:0];
					y = A1_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end					
				else begin
					
					draw_count= 18'b0;
					current_state = ERASE_A2;
					end
				end
		
			ERASE_A2: begin
				if (draw_count < 8'b1000_0000) begin
					x = A2_x + draw_count[1:0];
					y = A2_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_A2;
					end
				end
			UPDATE_A2: begin
					// update new  position
					// make sure that  can't move further past the left or right of the screen
					
					// check if reached edge of left and right
					if (A2_x >= 8'd144) begin
						a2_right = 1'b0;
						A2_x = 8'd144;
						end
					else if ((A2_x <= 8'd0) && (A2_y != 8'd0)) begin
						a2_right = 1'b1;
						A2_x = 8'd0;
						end
					// update x
					if (a2_right == 1'b1) begin
						A2_x = A2_x + 1'b1;
						end
					else begin
						A2_x = A2_x - 1'b1;
						end
					if (A2 == 1'b1) begin
						// if active, draw
						current_state = DRAW_A2;
					end
					else begin
						// inactive, go to next 
						current_state = ERASE_A3;
					end
				end
			DRAW_A2: begin
				if (draw_count < 8'b1000_0000) begin
					x = A2_x + draw_count[1:0];
					y = A2_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end					
				else begin
					draw_count= 18'b0;
					current_state = ERASE_A3;
					end
				end
			ERASE_A3: begin
				if (draw_count < 8'b1000_0000) begin
					x = A3_x + draw_count[1:0];
					y = A3_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_A3;
					end
				end
			UPDATE_A3: begin
					// update new position
					// make sure that can't move further past the left or right of the screen
					// check if reached edge of left and right
					if (A3_x >= 8'd144) begin
						a3_right = 1'b0;
						A3_x = 8'd144;
						end
					else if ((A3_x <= 8'd0) && (A3_y != 8'd0)) begin
						a3_right = 1'b1;
						A3_x = 8'd0;
						end
					// update x position
					if (a3_right == 1'b1) begin
						A3_x = A3_x + 1'b1;
						end
					else begin
						A3_x = A3_x - 1'b1;
						end
				
				if (A3 == 1'b1) begin
					// if active, draw
					current_state = DRAW_A3;
				end
				else begin
					// inactive, go to next 
					current_state = ERASE_A4;
				end
				
				end
			DRAW_A3: begin
				if (draw_count < 8'b1000_0000) begin
					x = A3_x + draw_count[1:0];
					y = A3_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end					
				else begin
					
					draw_count= 18'b0;
					current_state = ERASE_A4;
					end
				end

			ERASE_A4: begin
				if (draw_count < 8'b1000_0000) begin
					x = A4_x + draw_count[1:0];
					y = A4_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_A4;
					end
				end
			UPDATE_A4: begin
					// update new  position
					// make sure can't move further past the left or right of the screen
					// check if reached edge of left and right
					if (A4_x >= 8'd144) begin
						a4_right = 1'b0;
						A4_x = 8'd144;
						end
					else if ((A4_x <= 8'd0) && (A4_y != 8'd0)) begin
						a4_right = 1'b1;
						A4_x = 8'd0;
						end
					// update x
					if (a4_right == 1'b1) begin
						A4_x = A4_x + 1'b1;
						end
					else begin
						A4_x = A4_x - 1'b1;
						end

					if (A4 == 1'b1) begin
						// if active, draw
						current_state = DRAW_A4;
					end
				end
			DRAW_A4: begin
				if (draw_count < 8'b1000_0000) begin
					x = A4_x + draw_count[1:0];
					y = A4_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end					
				else begin
					draw_count= 18'b0;
					current_state = ERASE_B1;
					end
				end
			/* Main bottom base states, we added these states */
			ERASE_B1: begin
				if (draw_count < 8'b1000_0000) begin
					x = B1_x + draw_count[1:0];
					y = B1_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_B1;
					end
				end
			UPDATE_B1: begin
					// update new  position
					// make sure can't move further past the left or right of the screen
					// check if reached edge of left and right
					if (B1_x >= 8'd144) begin
						b1_right = 1'b0;
						B1_x = 8'd144;
						end
					else if ((B1_x <= 8'd0) && (B1_y != 8'd0)) begin
						b1_right = 1'b1;
						B1_x = 8'd0;
						end
					
					// update x position
					if (b1_right == 1'b1) begin
						B1_x = B1_x + 1'b1;
						end
					else begin
						B1_x = B1_x - 1'b1;
						end
					
					
					if (B1 == 1'b1) begin
						// if base is active, draw it
						current_state = DRAW_B1;
					end
					else begin
						// inactive, erase
						current_state = ERASE_B2;
					end
				end
			DRAW_B1: begin
				if (draw_count < 8'b1000_0000) begin
					x = B1_x + draw_count[1:0];
					y = B1_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end					
				else begin
					
					draw_count= 18'b0;
					current_state = ERASE_B2;
					end
				end
			ERASE_B2: begin
				if (draw_count < 8'b1000_0000) begin
					x = B2_x + draw_count[1:0];
					y = B2_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_B2;
					end
				end
			UPDATE_B2: begin
					// update new  position
					// make sure that  can't move further past the left or right of the screen
					
					// check if reached edge of left and right
					if (B2_x >= 8'd144) begin
						b2_right = 1'b0;
						B2_x = 8'd144;
						end
					else if ((B2_x <= 8'd0) && (B2_y != 8'd0)) begin
						b2_right = 1'b1;
						B2_x = 8'd0;
						end
					// update x
					if (b2_right == 1'b1) begin
						B2_x = B2_x + 1'b1;
						end
					else begin
						B2_x = B2_x - 1'b1;
						end
					if (B2 == 1'b1) begin
						// if active, draw
						current_state = DRAW_B2;
					end
					else begin
						// inactive, go to next 
						current_state = ERASE_B3;
					end
				end
			DRAW_B2: begin
				if (draw_count < 8'b1000_0000) begin
					x = B2_x + draw_count[1:0];
					y = B2_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end					
				else begin
					draw_count= 18'b0;
					current_state = ERASE_B3;
					end
				end
			ERASE_B3: begin
				if (draw_count < 8'b1000_0000) begin
					x = B3_x + draw_count[1:0];
					y = B3_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_B3;
					end
				end
			UPDATE_B3: begin
					// update new position
					// make sure can't move further past the left or right of the screen
					// check if reached edge of left and right
					if (B3_x >= 8'd144) begin
						b3_right = 1'b0;
						B3_x = 8'd144;
						end
					else if ((B3_x <= 8'd0) && (B3_y != 8'd0)) begin
						b3_right = 1'b1;
						B3_x = 8'd0;
						end
					// update x position
					if (b3_right == 1'b1) begin
						B3_x = B3_x + 1'b1;
						end
					else begin
						B3_x = B3_x - 1'b1;
						end
				
					if (B3 == 1'b1) begin
						// if active, draw
						current_state = DRAW_B3;
					end
					else begin
						// inactive, go to next 
						current_state = ERASE_B4;
					end
				end
			DRAW_B3: begin
				if (draw_count < 8'b1000_0000) begin
					x = B3_x + draw_count[1:0];
					y = B3_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end					
				else begin
					draw_count= 18'b0;
					current_state = ERASE_B4;
					end
				end
			ERASE_B4: begin
				if (draw_count < 8'b1000_0000) begin
					x = B4_x + draw_count[1:0];
					y = B4_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_B4;
					end
				end
			UPDATE_B4: begin
					// update new  position
					// make sure can't move further past the left or right of the screen
					// check if reached edge of left and right
					if (B4_x >= 8'd144) begin
						b4_right = 1'b0;
						B4_x = 8'd144;
						end
					else if ((B4_x <= 8'd0) && (B4_y != 8'd0)) begin
						b4_right = 1'b1;
						B4_x = 8'd0;
						end
					// update x
					if (b4_right == 1'b1) begin
						B4_x = B4_x + 1'b1;
						end
					else begin
						B4_x = B4_x - 1'b1;
						end

					if (B4 == 1'b1) begin
						// if active, draw
						current_state = DRAW_B4;
					end
				end
			DRAW_B4: begin
				if (draw_count < 8'b1000_0000) begin
					x = B4_x + draw_count[1:0];
					y = B4_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end					
				else begin
					draw_count= 18'b0;
					current_state = ERASE_C1;
					end
				end
				
			/* Main left base states, we added these states */
			ERASE_C1: begin
				if (draw_count < 8'b1000_0000) begin
					x = C1_x + draw_count[1:0];
					y = C1_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_C1;
					end
				end
			UPDATE_C1: begin
					// update new  position
					// make sure doesn't interfere with top and bottom bases
					if (C1_y >= 8'd108) begin
						c1_down = 1'b0;
						C1_y = 8'd108;
						end
					else if (C1_y <= 8'd20) begin
						c1_down = 1'b1;
						C1_y = 8'd20;
						end
					
					// update y position
					if (c1_down == 1'b1) begin
						C1_y = C1_y + 1'b1;
						end
					else begin
						C1_y = C1_y - 1'b1;
						end
					
					
				if (C1 == 1'b1) begin
					// if  is active, draw it
					current_state = DRAW_C1;
				end
				else begin
					//  inactive, erase
					current_state = ERASE_C2;
				end
				
				
				end
			DRAW_C1: begin
				if (draw_count < 8'b1000_0000) begin
					x = C1_x + draw_count[1:0];
					y = C1_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end					
				else begin
					draw_count= 18'b0;
					current_state = ERASE_C2;
					end
				end
			ERASE_C2: begin
				if (draw_count < 8'b1000_0000) begin
					x = C2_x + draw_count[1:0];
					y = C2_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_C2;
					end
				end
			UPDATE_C2: begin
					// update new position
					// make sure doesn't interfere with top and bottom bases
					if (C2_y >= 8'd108) begin
						c2_down = 1'b0;
						C2_y = 8'd108;
						end
					else if (C2_y <= 8'd20) begin
						c2_down = 1'b1;
						C2_y = 8'd20;
						end
					
					// update y position
					if (c2_down == 1'b1) begin
						C2_y = C2_y + 1'b1;
						end
					else begin
						C2_y = C2_y - 1'b1;
						end
	
					if (C2 == 1'b1) begin
						// if active, draw it
						current_state = DRAW_C2;
					end
					else begin
						//  inactive, erase
						current_state = ERASE_D1;
					end
				end
			DRAW_C2: begin
				if (draw_count < 8'b1000_0000) begin
					x = C2_x + draw_count[1:0];
					y = C2_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end					
				else begin
					draw_count= 18'b0;
					current_state = ERASE_D1;
					end
				end
			/* Main right base states, we added these states */
			ERASE_D1: begin
				if (draw_count < 8'b1000_0000) begin
					x = D1_x + draw_count[1:0];
					y = D1_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_D1;
					end
				end
			UPDATE_D1: begin
					// update new position
					// make sure doesn't interfere with top and bottom bases
					if (D1_y >= 8'd108) begin
						d1_down = 1'b0;
						D1_y = 8'd108;
						end
					else if (D1_y <= 8'd20) begin
						d1_down = 1'b1;
						D1_y = 8'd20;
						end
					
					// update y position
					if (d1_down == 1'b1) begin
						D1_y = D1_y + 1'b1;
						end
					else begin
						D1_y = D1_y - 1'b1;
						end
					
					
					if (D1 == 1'b1) begin
						// if active, draw it
						current_state = DRAW_D1;
					end
					else begin
						// inactive, erase
						current_state = ERASE_D2;
					end
				end
			DRAW_D1: begin
				if (draw_count < 8'b1000_0000) begin
					x = D1_x + draw_count[1:0];
					y = D1_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end					
				else begin
					draw_count= 18'b0;
					current_state = ERASE_D2;
					end
				end
			ERASE_D2: begin
				if (draw_count < 8'b1000_0000) begin
					x = D2_x + draw_count[1:0];
					y = D2_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_D2;
					end
				end
			UPDATE_D2: begin
					// update new position
					// make sure doesn't interfere with top and bottom bases
					if (D2_y >= 8'd108) begin
						d2_down = 1'b0;
						D2_y = 8'd108;
						end
					else if (D2_y <= 8'd20) begin
						d2_down = 1'b1;
						D2_y = 8'd20;
						end
					
					// update y position
					if (d2_down == 1'b1) begin
						D2_y = D2_y + 1'b1;
						end
					else begin
						D2_y = D2_y - 1'b1;
						end

					if (D2 == 1'b1) begin
						// if active, draw it
						current_state = DRAW_D2;
					end
					else begin
						//  inactive, erase
						current_state = ERASE_A_ENEMY;
					end
				end
			DRAW_D2: begin
				if (draw_count < 8'b1000_0000) begin
					x = D2_x + draw_count[1:0];
					y = D2_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end					
				else begin
					draw_count= 18'b0;
					current_state = ERASE_A_ENEMY;
					end
				end
			/* Main top enemy states */
			ERASE_A_ENEMY: begin
				if (draw_count < 8'b1000_0000) begin
					x = A_enemy_x+ draw_count[1:0];
					y = A_enemy_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_A_ENEMY;
					end
				end
			UPDATE_A_ENEMY: begin
				current_state = DRAW_A_ENEMY;
				if (A_enemy_y >= 8'd118) begin
					A_enemy_up = 1'b1;
					A_enemy_y = 8'd118;
					end
				else if (A_enemy_y <= 8'd0 && A_enemy_y != 8'd0) begin
					A_enemy_up = 1'b0;
					A_enemy_y = 8'd0;
					end
				// update y
				if (A_enemy_up == 1'b1) begin
						A_enemy_y = A_enemy_y - 1;
						end
				else begin
						A_enemy_y = A_enemy_y + 1;
						end
				if (A_enemy_y >= p_y && A_enemy_y <= p_y + 3)
					//  enemy reached near top of player, test if it hit the player
					current_state = TEST_A_HIT;
				end
			DRAW_A_ENEMY: begin 
				if (draw_count < 8'b1000_0000) begin
					x = A_enemy_x+ draw_count[1:0];
					y = A_enemy_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b100;
					end
				else begin
					draw_count= 18'b0;
					current_state = ERASE_B_ENEMY;
					end
				end
			
			TEST_A_HIT: begin
				// check if hit the player
				if (((A_enemy_x + 4 <= p_x + 8) && (A_enemy_x + 4 >= p_x)) && ((A_enemy_y + 4 <= p_y + 4) && (A_enemy_y + 4 >= p_y)))
					current_state = DEATH;
				else begin
					// set where the enemy deploys from
					// it deploys from the first active 
					if (A1 == 1'b1) begin
						A_enemy_x = A1_x + 8'd8;
						A_enemy_y = A1_y + 8'd8;
						end
					else if (A2 == 1'b1) begin
						A_enemy_x = A2_x + 8'd8;
						A_enemy_y = A2_y + 8'd8;
						end
					else if (A3 == 1'b1) begin
						A_enemy_x = A3_x + 8'd8;
						A_enemy_y = A3_y + 8'd8;
						end
					else if (A4 == 1'b1) begin
						A_enemy_x = A4_x + 8'd8;
						A_enemy_y = A4_y + 8'd8;
						end
					current_state = UPDATE_A_ENEMY;
				end
			end
			
			/* Main bottom enemy states, we added these states */
			ERASE_B_ENEMY: begin
				if (draw_count < 8'b1000_0000) begin
					x = B_enemy_x+ draw_count[1:0];
					y = B_enemy_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_B_ENEMY;
					end
				end
			UPDATE_B_ENEMY: begin
				current_state = DRAW_B_ENEMY;
				
				if (B_enemy_y >= 8'd118) begin
					B_enemy_up = 1'b1;
					B_enemy_y = 8'd118;
					end
				else if (B_enemy_y <= 8'd0 && B_enemy_y != 8'd0) begin
					B_enemy_up = 1'b0;
					B_enemy_y = 8'd0;
					end
				// update y
				if (B_enemy_up == 1'b1) begin
						B_enemy_y = B_enemy_y - 1;
						end
				else begin
						B_enemy_y = B_enemy_y + 1;
						end
				if (B_enemy_y >= p_y && B_enemy_y <= p_y + 4)
					//  enemy reached bottom of player, test if it hit the player
					current_state = TEST_B_HIT;
			end
			DRAW_B_ENEMY: begin 
				if (draw_count < 8'b1000_0000) begin
					x = B_enemy_x+ draw_count[1:0];
					y = B_enemy_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b100;
					end
				else begin
					draw_count= 18'b0;
					current_state = ERASE_C_ENEMY;
					end
				end
			
			
			TEST_B_HIT: begin
				// check if hit the player
				if (((B_enemy_x + 4 <= p_x + 8) && (B_enemy_x + 4 >= p_x)) && ((B_enemy_y <= p_y + 4) && (B_enemy_y >= p_y)))
					current_state = DEATH;
				else begin
					// set where the  enemy deploys from
					// it deploys from the first active 
					if (B1 == 1'b1) begin
						B_enemy_x = B1_x;
						B_enemy_y = B1_y;
						end
					else if (B2 == 1'b1) begin
						B_enemy_x = B2_x;
						B_enemy_y = B2_y;
						end
					else if (B3 == 1'b1) begin
						B_enemy_x = B3_x;
						B_enemy_y = B3_y;
						end
					else if (B4 == 1'b1) begin
						B_enemy_x = B4_x;
						B_enemy_y = B4_y;
						end
					current_state = UPDATE_B_ENEMY;
				end
			end

			/* Main left enemy states, we added these states */
			ERASE_C_ENEMY: begin
				// only go into these states at the right lvl
				if (lvl_up < 2'd1)
					current_state = WAIT;
				if (draw_count < 8'b1000_0000) begin
					x = C_enemy_x+ draw_count[1:0];
					y = C_enemy_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_C_ENEMY;
					end
				end
			UPDATE_C_ENEMY: begin
				current_state = DRAW_C_ENEMY;
				
				if (C_enemy_x >= 8'd118) begin 
					C_enemy_right = 1'b0;
					C_enemy_x = 8'd118;
					end
				else if (C_enemy_x <= 8'd0 && C_enemy_x != 8'd0) begin
					C_enemy_right = 1'b1;
					C_enemy_x = 8'd0;
					end
				// update x
				if (C_enemy_right == 1'b1) begin
						C_enemy_x = C_enemy_x + 1;
						end
				else begin
						C_enemy_x = C_enemy_x - 1;
						end
				if (C_enemy_x >= p_x && C_enemy_x <= p_x + 4)
					//  enemy reached player's left, test if it hit the player
					current_state = TEST_C_HIT;
			end
			DRAW_C_ENEMY: begin 
				if (draw_count < 8'b1000_0000) begin
					x = C_enemy_x+ draw_count[1:0];
					y = C_enemy_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b100;
					end
				else begin
					draw_count= 18'b0;
					current_state = ERASE_D_ENEMY;
					end
				end
			
			TEST_C_HIT: begin
				// check if hit the player
				if (((C_enemy_x + 4 <= p_x + 4) && (C_enemy_x + 4 >= p_x)) && ((C_enemy_y <= p_y + 4) && (C_enemy_y >= p_y - 4)))
					current_state = DEATH;
				else begin
					// set where the enemy deploys from
					// it deploys from the first alive 
					if (C1 == 1'b1) begin
						C_enemy_x = C1_x + 4;
						C_enemy_y = C1_y + 4;
						end
					else if (C2 == 1'b1) begin
						C_enemy_x = C2_x + 4;
						C_enemy_y = C2_y + 4;
						end
					current_state = UPDATE_C_ENEMY;
				end
			end
			
			/* Main right enemy states, we added these states */
			ERASE_D_ENEMY: begin
				// only enter states within the correct level
				if (lvl_up < 2'd2)
					current_state = WAIT;
				if (draw_count < 8'b1000_0000) begin
					x = D_enemy_x+ draw_count[1:0];
					y = D_enemy_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					end
				else begin
					draw_count= 18'b0;
					current_state = UPDATE_D_ENEMY;
					end
				end
			UPDATE_D_ENEMY: begin
				current_state = DRAW_D_ENEMY;
				
				if (D_enemy_x >= 8'd140) begin
					D_enemy_right = 1'b0;
					D_enemy_x = 8'd140;
					end
				else if (D_enemy_x <= 8'd0 && D_enemy_x != 8'd0) begin
					D_enemy_right = 1'b1;
					D_enemy_x = 8'd0;
					end
				// update x
				if (D_enemy_right == 1'b1) begin
						D_enemy_x = D_enemy_x + 1;
						end
				else begin
						D_enemy_x = D_enemy_x - 1;
						end
				if (D_enemy_x >= p_x && D_enemy_x <= p_x + 4)
					//  enemy reached player's right, test if it hit the player
					current_state = TEST_D_HIT;
				end
			DRAW_D_ENEMY: begin 
				if (draw_count < 8'b1000_0000) begin
					x = D_enemy_x+ draw_count[1:0];
					y = D_enemy_y + draw_count[3:2];
					draw_count = draw_count + 1'b1;
					colour = 3'b100;
					end
				else begin
					draw_count= 18'b0;
					current_state = WAIT;
					end
				end
			
			TEST_D_HIT: begin
				// check if hit the player
				if (((D_enemy_x <= p_x + 4) && (D_enemy_x >= p_x)) && ((D_enemy_y <= p_y + 4) && (D_enemy_y >= p_y)))
					current_state = DEATH;
				else begin
					// set where the enemy deploys from
					// it deploys from the first active 
					if (D1 == 1'b1) begin
						D_enemy_x = D1_x;
						D_enemy_y = D1_y;
						end
					else if (D2 == 1'b1) begin
						D_enemy_x = D2_x;
						D_enemy_y = D2_y;
						end
					current_state = UPDATE_D_ENEMY;
				end
			end
			
			/* the death state */
			DEATH: begin
				// when player is hit, end game with dark screen
				if (draw_count < 17'b1000_0000_0000_0000_0) begin
					x = draw_count[7:0];
					y = draw_count[15:8];
					draw_count = draw_count + 1'b1;
					colour = 3'b000;
					collided = 1'b1;
					end
				else begin
					draw_count = 18'b0;
					current_state = DEATH;
					end
				end
			
			// make the default state where it should be initialized
			default: current_state = RESET;
		endcase
	end
	
endmodule
 
// module counts a number of clock ticks to simulate 60 frames per second
// send go signal each frame counted
module frame_counter(input clock, output reg go);
	// CREDIT TO: MATTHEW CHAU AND ZIXIONG LIN
	reg [19:0] count;
	// 50 000 000 / 60 frames = 833 333 seconds per frame
	// 833 333 = 20'b11001011011100110100
	always@(posedge clock)
    begin
        if (count == 20'b11001011011100110100) begin
		  count = 20'b0000_0000_0000_0000_0000;
		  go = 1'b1;
		  end
        else begin
			count = count + 1'b1;
			go = 1'b0;
		  end
    end
endmodule 



module RateDivider(clk, rate, current_rate);
	// CREDIT TO: ALEX WONG ET AL
	input clk;
	input[28:0] rate;
	output[28:0] current_rate;
	reg[28:0] out= 0;
	assign current_rate = out;
	
    // every time the clock ticks, out decreases by 1, and if its 0 then reset it to the inputted rate
    // output the out variable
	always @(posedge clk)
	begin
		if(out == 0)
			out <= rate;
		else
			out <= out - 1'b1;
	end

endmodule

module time_counter(binary_time, CLOCK_50, hex_0, hex_1, hex_2, collided, key_press, ledr, lvl);
	// CREDIT TO: ALEX WONG ET AL
    // a counter used to display the amount of time the player have lasted through the 7 segment display

    input [3:0] binary_time;
	input CLOCK_50;
	input collided; // stops the counter if its collided
    input key_press; // the key to reset the counter
    output [6:0] hex_0;
    output [6:0] hex_1;
    output [6:0] hex_2;
	 output [1:0] ledr;
	 output [1:0] lvl;
	 
	 
    
    // the register used to store the second and third digits
    reg [3:0] digit2 = 4'b0;
    reg [3:0] digit3 = 4'b0;
    reg in_game = 1'b1;
	 reg [1:0] ledr_out = 0;
	 assign ledr = ledr_out;
	 assign lvl = ledr_out;
    // hex decoder used to help translate binary to the 7 segment displays in decimal
    hex_decoder h0(
        .hex_digit(binary_time[3:0]),
        .segments(hex_0)
        );

    hex_decoder h1(
        .hex_digit(digit2[3:0]),
        .segments(hex_1)
        );

    hex_decoder h2(
        .hex_digit(digit3[3:0]),
        .segments(hex_2)
        );

    // increase the values of digit 2 and digit 3 whenever the value before it reaches 10
    // if pipe and box has collided then set all digits to 0
    always @(posedge CLOCK_50)
        begin
		  if(~collided) begin
			  if (binary_time == 4'd10) begin
					ledr_out <= ledr_out + 1;
					digit2 <= digit2 + 1'b1;
					end
			  if (digit2 == 4'd10)
					begin
					ledr_out <= ledr_out + 1;
					digit3 <= digit3 + 1'b1;
					digit2 <= 4'b0;
					end
				if (digit3 == 4'd10)
					digit3 <= 4'b0;
				end
			if (key_press) begin
				ledr_out <= 2'd0;
				digit2 <= 4'd0;
				digit3 <= 4'd0;
				end
        end
		  

endmodule

module clock(CLOCK_50, clk_speed, current_number, collided, key_press);
	// CREDIT TO: ALEX WONG ET AL
    
    // a clock that allows the user to choose the how many clocks cycle to send a signal
	input CLOCK_50; // the base clock, ticks once every 1/50 million seconds
	input[2:0] clk_speed; // the input to choose the clock speed
    input collided; // if the pipe and box has collided then stop the clock
    input key_press; // the key to reset the clock back to 0 
	output [3:0] current_number; // it outputs how many ticks it has counted
	
    // use a register to store the number of ticks and output it
	reg[3:0] q = 4'b0;
	assign current_number = q;
	reg Enable;
	
    // the wires for the different clokc speeds
	wire[28:0] counter_50; // the base clock speed
	wire[28:0] counter_1; // 1sec / tick
	wire[28:0] counter_025; //0.25 second/tick
	wire[28:0] counter_05; // 0.5 seconds/tick
    wire[28:0] counter_01; //0.1second/tick
	wire[28:0] wire_025Hz = 28'b1011111010111100001000000000;
	wire[28:0] wire_05Hz = 28'b0101111101011110000100000000;
	wire[28:0] wire_1Hz = 28'b0010111110101111000010000000;
	wire[28:0] wire_01Hz = 28'b0000010011000100101101000000;
	wire[28:0] wire_50MHz = 28'b0000000000000000000000000001;
	
    // create different rateDivider modules to control the speed

    // rate divider for the base clock speed
	RateDivider rDivider_50 (
		.clk(CLOCK_50),
		.rate(wire_50MHz),
		.current_rate(counter_50)
		);

    // rate divider for the 1 second / tick 
	RateDivider rDivider_1 (
		.clk(CLOCK_50),
		.rate(wire_1Hz),
		.current_rate(counter_1)
		);
	
    // the 0.5 second per tick
	RateDivider rDivider_05 (
		.clk(CLOCK_50),
		.rate(wire_05Hz),
		.current_rate(counter_05)
		);

    // 0.25 second per tick rate divider
	RateDivider rDivider_025 (
		.clk(CLOCK_50),
		.rate(wire_025Hz),
		.current_rate(counter_025)
		);

    // the 0.1 second / tick rate divider
	RateDivider rDivider_01 (
        .clk(CLOCK_50),
        .rate(wire_01Hz),
        .current_rate(counter_01)
        );

    // check if the different clock speeds reaches 0, so that it counts as one tick

	always@(posedge CLOCK_50)
	begin
		if (clk_speed == 3'd0)
			Enable <= (counter_50 == 28'b0000000000000000000000000000) ? 1 : 0;
		else if (clk_speed == 3'd1)
			Enable <= (counter_1 == 28'b0000000000000000000000000000) ? 1 : 0;
		else if (clk_speed == 3'd2)
			Enable <= (counter_05 == 28'b0000000000000000000000000000) ? 1 : 0;
		else if (clk_speed == 3'd3)
			Enable <= (counter_025 == 28'b0000000000000000000000000000) ? 1 : 0;
		else if (clk_speed == 3'd4)
			Enable <= (counter_01 == 28'b0000000000000000000000000000) ? 1 : 0;
	end

    // once the clock ticks once, the output goes up by one
    // if box and pipe has collided then stop the clock
	always@(posedge CLOCK_50)
	begin
		if(q == 4'd10 || key_press == 1'b1)
			q <= 0;
		else if(Enable == 1'b1 && ~collided)
			q <= q + 1'b1;
	end
endmodule

module hex_decoder(hex_digit, segments);
    // decodes binary to seven segment display outputs
    // CREDIT TO: BRIAN HARRINGTON
    
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            default: segments = 7'b100_0000;
        endcase
endmodule
