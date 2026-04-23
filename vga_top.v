`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:18:00 12/14/2017 
// Design Name: 
// Module Name:    vga_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
// Date: 04/04/2020
// Author: Yue (Julien) Niu
// Description: Port from NEXYS3 to NEXYS4
//////////////////////////////////////////////////////////////////////////////////
module vga_top (
    input ClkPort,
    input BtnC,
    input BtnU,
    input BtnR,
    input BtnL,
    input BtnD,
    //VGA signal
    output hSync,
    vSync,
    output [3:0] vgaR,
    vgaG,
    vgaB,


    // LEDs
    output Ld1,
    Ld2,
    Ld3,
    Ld4,
    Ld12,
    Ld13,
    Ld14,
    Ld15,

    //SSG signal 
    output An0,
    An1,
    An2,
    An3,
    An4,
    An5,
    An6,
    An7,
    output Ca,
    Cb,
    Cc,
    Cd,
    Ce,
    Cf,
    Cg,
    Dp,

    output MemOE,
    MemWR,
    RamCS,
    QuadSpiFlashCS
);

  // wires are inputs while regs are outputs for top design
  wire Reset;
  assign Reset = BtnC;
  wire bright;
  wire [9:0] hc, vc;
  wire [15:0] score;
  wire up, down, left, right;
  wire [3:0] anode;
  wire [11:0] rgb;
  wire rst;

  wire [11:0] mario_rgb;
  // wire collision;
  // wire grounded, jumping_up, direction;
  // wire [9:0] y_x, y_y;
  wire [9:0] x, y;
  // These are the bits of the states that will light up the LED

  //ON_GROUND = 4'b0000, MID_AIR = 4'b0001, UNK = 4'b0011;
  //MID_AIR_UP = 4'b0000, MID_AIR_DOWN = 4'b0001, MID_AIR_START_DONE = 4'b0011;

  // NOTE: inputs in .v file can connect to wire and reg from the top file
  // NOTE: Outputs in the .v file can only connect to wire from the top file


  // These bits under are outputs in the .v file so use wire in the top file
  // Normal State bits
  //wire On_Ground, Mid_Air, Unk;
  wire [3:0] state_for_LED;

  // Sub State Bits
  //wire Mid_Air_Up, Mid_Air_Down, Mid_Air_Start_Done;
  wire [3:0] sub_state_for_LED;
  reg  [3:0] SSD;
  wire [3:0] SSD3, SSD2, SSD1, SSD0;
  reg  [ 7:0] SSD_CATHODES;
  wire [ 1:0] ssdscan_clk;

  reg  [27:0] DIV_CLK;
  always @(posedge ClkPort, posedge Reset) begin : CLOCK_DIVIDER
    if (Reset) DIV_CLK <= 0;
    else DIV_CLK <= DIV_CLK + 1'b1;
  end
  wire move_clk;
  // The gravity clk will be slower the move_clk to decrease the gravity fall
  wire gravity_clk;
  assign move_clk = DIV_CLK[19];  //slower clock to drive the movement of objects on the vga screen
  assign gravity_clk=DIV_CLK[21];	// Even slower close to make the gravity not make mario fall too fast
  wire [11:0] background;

  // These modules are like functions
  display_controller dc (
      .clk(ClkPort),
      .hSync(hSync),
      .vSync(vSync),
      .bright(bright),
      .hCount(hc),
      .vCount(vc)
  );
  // block_controller sc(.clk(move_clk), .bright(bright), .rst(BtnC), .up(BtnU), .down(BtnD),.left(BtnL),.right(BtnR),.hCount(hc), .vCount(vc), .rgb(rgb), .background(background));

  // wire On_Ground, Mid_Air, Unk;
  //wire Mid_Air_Up, Mid_Air_Down, Mid_Air_Start_Done;
  block_controller sc (
      .clk(ClkPort),
      .move_clk(move_clk),
      .gravity_clk(gravity_clk),
      .bright(bright),
      .rst(BtnC),
      .up(BtnU),
      .down(BtnD),
      .left(BtnL),
      .right(BtnR),
      .hCount(hc),
      .vCount(vc),
      .rgb(rgb),
      .mario_rgb(mario_rgb),
      .xpos(x),
      .ypos(y),
      .background(background),
      .state_for_LED(state_for_LED),
      .sub_state_for_LED(sub_state_for_LED)
  );

  // Display Mario in a 32x32 box; ROM is 40 rows tall, so scale vertically (*5/4).
  wire [9:0] mario_dy = vc - y;           // 0..31 inside the box
  wire [9:0] mario_row = (mario_dy * 5) >> 2;  // 0..39 into the ROM
  wire [9:0] mario_col = hc - x;               // 0..31 (no scale)
  mario_rom mario_rom_unit (
      .clk(ClkPort),
      .row(mario_row),
      .col(mario_col),
      .color_data(mario_rgb)
  );

  // instantiate mario sprite circuit
  // mario_sprite mario_unit (
  //     .clk(ClkPort),
  //     .reset(BtnC),
  //     .btnU(BtnU),
  //     .btnL(BtnL),
  //     .btnR(BtnR),
  //     .video_on(1),
  //     .x(x),
  //     .y(y),
  //     .grounded(grounded),
  //     .game_over_mario(game_over_mario),
  //     .collision(collision),
  //     .rgb_out(mario_rgb),
  //     .y_x(y_x),
  //     .y_y(y_y),
  //     .jumping_up(jumping_up),
  //     .direction(direction)
  // );
  //

  assign vgaR = rgb[11 : 8];
  assign vgaG = rgb[7 : 4];
  assign vgaB = rgb[3 : 0];

  // disable mamory ports
  assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;

  //------------
  // SSD (Seven Segment Display)
  // reg [3:0]	SSD;
  // wire [3:0]	SSD3, SSD2, SSD1, SSD0;

  //SSDs display 
  //to show how we can interface our "game" module with the SSD's, we output the 12-bit rgb background value to the SSD's
  assign SSD3 = 4'b0000;
  assign SSD2 = background[11:8];
  assign SSD1 = background[7:4];
  assign SSD0 = background[3:0];


  // need a scan clk for the seven segment display 

  // 100 MHz / 2^18 = 381.5 cycles/sec ==> frequency of DIV_CLK[17]
  // 100 MHz / 2^19 = 190.7 cycles/sec ==> frequency of DIV_CLK[18]
  // 100 MHz / 2^20 =  95.4 cycles/sec ==> frequency of DIV_CLK[19]

  // 381.5 cycles/sec (2.62 ms per digit) [which means all 4 digits are lit once every 10.5 ms (reciprocal of 95.4 cycles/sec)] works well.

  //                  --|  |--|  |--|  |--|  |--|  |--|  |--|  |--|  |   
  //                    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 
  //  DIV_CLK[17]       |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
  //
  //               -----|     |-----|     |-----|     |-----|     |
  //                    |  0  |  1  |  0  |  1  |     |     |     |     
  //  DIV_CLK[18]       |_____|     |_____|     |_____|     |_____|
  //
  //         -----------|           |-----------|           |
  //                    |  0     0  |  1     1  |           |           
  //  DIV_CLK[19]       |___________|           |___________|
  //

  assign ssdscan_clk = DIV_CLK[19:18];
  assign An0 = !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
  assign An1 = !(~(ssdscan_clk[1]) && (ssdscan_clk[0]));  // when ssdscan_clk = 01
  assign An2 = !((ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
  assign An3 = !((ssdscan_clk[1]) && (ssdscan_clk[0]));  // when ssdscan_clk = 11
  // Turn off another 4 anodes
  assign {An7, An6, An5, An4} = 4'b1111;

  always @(ssdscan_clk, SSD0, SSD1, SSD2, SSD3) begin : SSD_SCAN_OUT
    case (ssdscan_clk)
      2'b00: SSD = SSD0;
      2'b01: SSD = SSD1;
      2'b10: SSD = SSD2;
      2'b11: SSD = SSD3;
    endcase
  end

  // Following is Hex-to-SSD conversion
  always @(SSD) begin : HEX_TO_SSD
    case (SSD)  // in this solution file the dot points are made to glow by making Dp = 0
      //                                                                abcdefg,Dp
      4'b0000: SSD_CATHODES = 8'b00000010;  // 0
      4'b0001: SSD_CATHODES = 8'b10011110;  // 1
      4'b0010: SSD_CATHODES = 8'b00100100;  // 2
      4'b0011: SSD_CATHODES = 8'b00001100;  // 3
      4'b0100: SSD_CATHODES = 8'b10011000;  // 4
      4'b0101: SSD_CATHODES = 8'b01001000;  // 5
      4'b0110: SSD_CATHODES = 8'b01000000;  // 6
      4'b0111: SSD_CATHODES = 8'b00011110;  // 7
      4'b1000: SSD_CATHODES = 8'b00000000;  // 8
      4'b1001: SSD_CATHODES = 8'b00001000;  // 9
      4'b1010: SSD_CATHODES = 8'b00010000;  // A
      4'b1011: SSD_CATHODES = 8'b11000000;  // B
      4'b1100: SSD_CATHODES = 8'b01100010;  // C
      4'b1101: SSD_CATHODES = 8'b10000100;  // D
      4'b1110: SSD_CATHODES = 8'b01100000;  // E
      4'b1111: SSD_CATHODES = 8'b01110000;  // F    
      default: SSD_CATHODES = 8'bXXXXXXXX;  // default is not needed as we covered all cases
    endcase
  end

  // reg [7:0]  SSD_CATHODES;
  assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};

  /*
		// Normal State bits
	reg On_Ground, Mid_Air, Unk;

	// Sub State Bits
	reg Mid_Air_Up, Mid_Air_Down, Mid_Air_Start_Done;
	
	*/

  // Debuggin LEDs
  assign {Ld15, Ld14, Ld13, Ld12} = state_for_LED[3:0];
  assign {Ld4, Ld3, Ld2, Ld1} = sub_state_for_LED[3:0];
endmodule
