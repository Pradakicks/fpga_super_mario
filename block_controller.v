`timescale 1ns / 1ps

// typedef struct packed {
//     logic [7:0] opcode;
//     logic [3:0] source_reg;
//     logic [3:0] dest_reg;
// } instruction_t;

// instruction_t my_instr;
// assign my_instr.opcode = 8'hA5;
//.On_Ground(On_Ground), .Mid_Air(Mid_Air), .Unk(Unk),
//.Mid_Air_Up(Mid_Air_Up), .Mid_Air_Down(Mid_Air_Down), .Mid_Air_Start_Done(Mid_Air_Start_Done)
module block_controller (
    input clk,
    input move_clk, //This clock must be a slow enough clock to view the changing positions of the objects
    input gravity_clk, // This clock must be even slower than the move_clk in order for mario not to fall too fast
    input bright,
    input rst,
    input up,
    input down,
    input left,
    input right,
    input [9:0] hCount,
    vCount,
    input [11:0] mario_rgb,
    input [11:0] brick_rgb,
    output reg [11:0] rgb,
    output reg [11:0] background,
    output reg [9:0] xpos,
    ypos,
    // Normal State bits
    // NOTE: Need to specify it is 4 bits
    output [3:0] state_for_LED,

    // Sub State bits
    output [3:0] sub_state_for_LED
);
  wire block_fill;
  wire floor_fill;

  // This is like a boolean to see if mario is still above the ground
  wire above_ground;
  wire at_or_below_ground;
  //these two values dictate the center of the block, incrementing and decrementing them leads the block to move in certain directions

  // This is the gravity velocity
  reg [9:0] gravity_speed;

  // Color parameters
  parameter RED = 12'b1111_0000_0000;
  parameter BLUE = 12'b0000_0000_1111;

  // Speed/Acceleration parameters
  parameter GRAVITY_ACCELERATION = 1;

  // Ground Parameters
  parameter GROUND = 400;

  // States
  reg [3:0] state;
  // The only purpose of this is to delay a state if something state change runs too fast. This will be used to temporarily delay for another clk
  reg [3:0] state_delay;
  // reg [3:0] state_s;
  // reg [3:0] state_ss;

  localparam
  //ON_GROUND = 4'b0001, MID_AIR = 4'b0010, UNK = 4'bXXXX;
  // Using gray code for synchronizing from move_clk to gravity_clk
  ON_GROUND = 4'b0000, MID_AIR = 4'b0001, UNK = 4'b0011;

  // Sub States
  reg [3:0] sub_state;
  // These are gray coded because I will be synchronizing from gravity_clk to move_clk. I want to make it so only 1 bit changes at a time so no metastability occurs
  localparam
	MID_AIR_UP = 4'b0000, MID_AIR_DOWN = 4'b0001, MID_AIR_START_DONE = 4'b0011;//4'b1000; //4'b0011;

  localparam GRAVITY_SPEED_BASE = 5;

  // Assigning state to state bits for LED
  assign state_for_LED = state;
  assign sub_state_for_LED = sub_state;

  wire enable;
  //assign enable = (gravity_speed == 5) && ()
  //IMPORTANT: NEED TO ADD TWO CLKS IN TERMS OF GRAVITY_CLK RAHTER THAN MOVE_CLK
  // Synchronizing sub_state for transitioning from move_clk to gravity_clk
  reg [3:0] state_s, state_ss, sub_state_s, sub_state_ss;
  genvar state_count;
  generate
    // sub_state_count < 4 because there are 4 bits in the sub_state and we want to iterate over those 4 particular bits
    for (state_count = 0; state_count < 4; state_count = state_count + 1) begin
      always @(posedge gravity_clk) begin
        state_s[state_count] <= state[state_count];
        state_ss[state_count] <= state_s[state_count];
        sub_state_s[state_count] <= sub_state[state_count];
        sub_state_ss[state_count] <= sub_state_s[state_count];
      end
    end
  endgenerate

  // Synchronization for any other variable in general
  // This width localparam is 9 in order to iterate over 10 bits to work with gravity_speed
  localparam WIDTH = 10;

  // This is just a vector of bits, and not an array. Could be used like an array though
  reg [WIDTH-1:0] gravity_speed_s, gravity_speed_ss;
  genvar count;
  generate
    for (count = 0; count < WIDTH; count = count + 1) begin
      always @(posedge move_clk) begin
        gravity_speed_s[count]  <= gravity_speed[count];
        gravity_speed_ss[count] <= gravity_speed_s[count];
      end
    end
  endgenerate

  // Assign Statements/Transition Arrows
  assign above_ground = (ypos < GROUND);
  assign almost_at_or_below_ground = (ypos >= (GROUND - gravity_speed_ss));
  /*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/


  //Error is below here
  // ---------------------------------------------------------------------------------------------------------------
  always @(*) begin

    if (~bright)  //force black if not inside the display area
      rgb = 12'b0000_0000_0000;

    // else if(block_fill && (state == ON_GROUND))
    // //else if(block_fill && (sub_state_ss == MID_AIR_START_DONE))
    // 	rgb = 12'hA54 ;	//Brown
    // else if(block_fill && (state_ss == MID_AIR))
    // //else if(block_fill && (sub_state_ss == MID_AIR_START_DONE))
    // 	rgb = 12'hFC0 ;	//Orange
    // Test to see if sub statae is in MID_AIR_DOWN
    //else if(block_fill && (sub_state == MID_AIR_DOWN))
    //rgb = 12'hA0A;	//Dark purple
    // else if (block_fill) rgb = RED;
    else if (block_fill && mario_rgb != 12'b011011011110) rgb = mario_rgb;
    // else if (block_fill) rgb = BLUE;
    else if (floor_fill) rgb = brick_rgb;
    else
      rgb = background;

  end
  // Mario drawn in a 16x16 box; xpos/ypos is the top-left corner.
  assign block_fill = vCount >= ypos && vCount < (ypos + 16) && hCount >= xpos && hCount < (xpos + 16);
  // Floor begins at GROUND (below Mario's feet) and runs to the bottom of the screen.
  assign floor_fill = vCount >= (GROUND + 16);

  always @(posedge move_clk, posedge rst) begin
    if (rst) begin
      //rough values for center of screen
      xpos <= 450;
      // ypos<=250;
      ypos <= 400;
      // gravity_speed<=2;
      state <= ON_GROUND;

      // This is the problem
      sub_state <= MID_AIR_START_DONE;
    end else if (move_clk) begin

      /* Note that the top left of the screen does NOT correlate to vCount=0 and hCount=0. The display_controller.v file has the 
			synchronizing pulses for both the horizontal sync and the vertical sync begin at vcount=0 and hcount=0. Recall that after 
			the length of the pulse, there is also a short period called the back porch before the display area begins. So effectively, 
			the top left corner corresponds to (hcount,vcount)~(144,35). Which means with a 640x480 resolution, the bottom right corner 
			corresponds to ~(783,515).  
		*/

      // Button Inputs To Control Mario
      if (right) begin
        xpos <= xpos + 2;  //change the amount you increment to make the speed faster 
        if(xpos==800) //these are rough values to attempt looping around, you can fine-tune them to make it more accurate- refer to the block comment above
          xpos <= 150;
      end else if (left) begin
        xpos <= xpos - 2;
        if (xpos == 150) xpos <= 800;
      end

      // else if(up) begin
      // 	//ypos<=ypos-50;
      // 	state <= MID_AIR;
      // 	sub_state <= MID_AIR_UP;

      // 	if(ypos==34)
      // 		ypos<=514;
      // end


      // if(above_ground) begin
      // 	ypos <= ypos + gravity_speed;
      // 	gravity_speed <= gravity_speed + GRAVITY_ACCELERATION;

      // end

      case (state)
        ON_GROUND: begin
          // if(above_ground) 
          // begin
          // 	state <= MID_AIR;
          // end

          //sub_state = MID_AIR_START_DONE;
          // Might need to add and
          if(up)
					//if(up && (gravity_speed_ss == 5))
					//if(up && (gravity_speed_ss <= 5)) 
					begin
            // 50 is the speed of the initial jump
            ypos <= ypos - 50;
            state <= MID_AIR;
            sub_state <= MID_AIR_UP;

            if (ypos == 34) ypos <= 514;
          end
        end

        MID_AIR: begin
          // Might have to make a slower clk for this in order to not fall down too fast

          case (sub_state)
            MID_AIR_UP: begin
              //ypos <= ypos - gravity_speed;

              // If gravity_speed_ss is greater than 5, then it is still getting the fast speeds from the last fall of the last jump

              //ypos <= ypos - gravity_speed_ss;

              if (gravity_speed_ss > GRAVITY_SPEED_BASE) begin
                ypos <= ypos - GRAVITY_SPEED_BASE;
              end else begin
                ypos <= ypos - gravity_speed_ss;
              end
              // If mario reaeched the apex of the jump
              if (gravity_speed_ss == 0) begin
                sub_state <= MID_AIR_DOWN;
              end
            end
            MID_AIR_DOWN: begin
              //ypos <= ypos + gravity_speed;
              ypos <= ypos + gravity_speed_ss;
              if (almost_at_or_below_ground) begin
                //If this doesn't work, then move the state <= ON_GROUND to a later if condition when the falling down does actual touch the ground
                sub_state = MID_AIR_START_DONE;

                //Or add three clks here somehow
                //state_s <= ON_GROUND;
                //state_ss <= state_s;
                //state <= state_ss;
                state_delay <= ON_GROUND;
                state <= state_delay;
                //state <= ON_GROUND;
                sub_state <= MID_AIR_START_DONE;

                ypos <= GROUND;
                //gravity_speed <= 2;
              end
            end
          endcase
          //ypos <= ypos + gravity_speed;
          // gravity_speed <= gravity_speed + GRAVITY_ACCELERATION;

          /*
					// Have this if condition in move_clk in order to get the faster clock accurate measurements
					if(at_or_below_ground)
					begin
						state <= ON_GROUND;
						//sub_state <= MID_AIR_START_DONE;
						ypos <= GROUND;
						//gravity_speed <= 2;
					end
*/
        end

        default: state <= UNK;
      endcase

      /*
			else if(down) begin
				ypos<=ypos+2;
				if(ypos==514)
					ypos<=34;
			end
			*/
    end
  end


  // // This always is for the gravity clk
  always @(posedge gravity_clk, posedge rst) begin


    if (rst) begin
      gravity_speed <= GRAVITY_SPEED_BASE;
      //sub_state <= MID_AIR_START_DONE;
    end else begin

      //case(state)
      case (state_ss)


        // ON_GROUND:
        // begin

        // end
        ON_GROUND: begin
          case (sub_state_ss)
            MID_AIR_START_DONE: begin
              gravity_speed <= GRAVITY_SPEED_BASE;
            end
          endcase
        end
        MID_AIR: begin
          //gravity_speed <= gravity_speed + GRAVITY_ACCELERATION;

          case (sub_state_ss)
            //MID_AIR_UP = 4'b0001, MID_AIR_DOWN = 4'b0010, MID_AIR_UNK = 4'bXXXX;
            MID_AIR_UP: begin

              if (gravity_speed > GRAVITY_SPEED_BASE) begin
                gravity_speed <= GRAVITY_SPEED_BASE - GRAVITY_ACCELERATION;
              end else begin
                gravity_speed <= gravity_speed - GRAVITY_ACCELERATION;
              end



              // // If gravity_speed is greater than 5, then it is still 
              // if(gravity_speed > 5)
              // begin
              // 	gravity_speed <= 5 - GRAVITY_ACCELERATION;
              // end
              /*
							// Once it the speed reaches 0, that means that mario is at the highest point of the jump
							if(gravity_speed == 0)
							begin
								sub_state <= MID_AIR_DOWN;
							end
							*/
            end
            MID_AIR_DOWN: begin
              gravity_speed <= gravity_speed + GRAVITY_ACCELERATION;
            end
            // MID_AIR_START_DONE:
            // begin
            // 	gravity_speed <= 5;
            // end
          endcase
        end


        // if(sub_state_ss == MID_AIR_START_DONE)
        // begin
        // 	gravity_speed <= 5;
        // end
        //default:

      endcase

      // if(sub_state_ss == MID_AIR_START_DONE)
      // begin
      // 	gravity_speed <= 5;
      // end
    end



  end


  //the background color reflects the most recent button press
  always @(posedge move_clk, posedge rst) begin
    if (rst) background <= 12'b1111_1111_1111;
    // else 
    // if(right)
    // 	background <= 12'b1111_1111_0000;
    // else if(left)
    // 	background <= 12'b0000_1111_1111;
    // else if(down)
    // 	background <= 12'b0000_1111_0000;
    // else if(up)
    // 	background <= 12'b0000_0000_1111;
  end



endmodule
