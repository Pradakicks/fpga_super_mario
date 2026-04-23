`timescale 1ns / 1ps

// 16x16 ground/brick tile. Meant to be tiled across the screen by
// indexing with the low 4 bits of hCount/vCount.
module brick_rom (
    input  wire        clk,
    input  wire [9:0]  row,
    input  wire [9:0]  col,
    output reg  [11:0] color_data
);

  reg [3:0] r, c;
  always @(posedge clk) begin
    r <= row[3:0];
    c <= col[3:0];
  end

  // Palette (12-bit RGB: 4 bits R, 4 G, 4 B)
  localparam [11:0] LIGHT = 12'hE96;  // tan highlight
  localparam [11:0] MED   = 12'hC74;  // mid brown (brick body)
  localparam [11:0] DARK  = 12'h830;  // dark brown (mortar / shadow)
  localparam [11:0] BLACK = 12'h000;

  always @* begin
    if (r <= 4'd1)
      color_data = LIGHT;                         // top highlight band
    else if (r == 4'd15)
      color_data = BLACK;                         // bottom shadow line
    else if (r == 4'd2 || r == 4'd8)
      color_data = DARK;                          // horizontal mortar
    else if (r <= 4'd7 && (c == 4'd7 || c == 4'd8))
      color_data = DARK;                          // upper brick vertical mortar (centered)
    else if (r >= 4'd9 && (c == 4'd0 || c == 4'd15))
      color_data = DARK;                          // lower brick vertical mortar (offset / edges)
    else
      color_data = MED;                           // brick body
  end

endmodule
