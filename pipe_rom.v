`timescale 1ns / 1ps

// 32 wide x 48 tall green pipe sprite. Top 16 rows are the "lip" (full 32
// wide). Bottom 32 rows are the shaft, 28 wide centered (cols 2..29). Outside
// either region the ROM emits 12'h001 as a transparency sentinel.
module pipe_rom (
    input  wire        clk,
    input  wire [9:0]  row,
    input  wire [9:0]  col,
    output reg  [11:0] color_data
);

  reg [5:0] r;
  reg [4:0] c;
  always @(posedge clk) begin
    r <= row[5:0];
    c <= col[4:0];
  end

  localparam [11:0] LIME   = 12'h2E2;  // bright pipe green
  localparam [11:0] LIGHT  = 12'hAFA;  // highlight band
  localparam [11:0] DARK   = 12'h070;  // shadow band
  localparam [11:0] BLACK  = 12'h000;
  localparam [11:0] TRANS  = 12'h001;

  wire in_lip   = (r < 6'd16);
  wire in_shaft = (r >= 6'd16) && (r < 6'd48) && (c >= 5'd2) && (c <= 5'd29);

  always @* begin
    if (in_lip) begin
      // Lip outline: top row, bottom row, left and right edges.
      if (r == 6'd0 || r == 6'd15 || c == 5'd0 || c == 5'd31)
        color_data = BLACK;
      else if (c <= 5'd3)
        color_data = LIGHT;            // left highlight
      else if (c >= 5'd28)
        color_data = DARK;             // right shadow
      else
        color_data = LIME;
    end else if (in_shaft) begin
      // Shaft outline: only left/right edges (no top/bottom — pipe extends to floor).
      if (c == 5'd2 || c == 5'd29)
        color_data = BLACK;
      else if (c == 5'd3)
        color_data = LIGHT;
      else if (c == 5'd28)
        color_data = DARK;
      else
        color_data = LIME;
    end else begin
      color_data = TRANS;
    end
  end

endmodule
