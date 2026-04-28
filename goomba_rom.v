`timescale 1ns / 1ps

// 16x16 Goomba sprite. Outputs 12'h001 outside the Goomba silhouette so the
// caller can treat it as transparent.
module goomba_rom (
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

  localparam [11:0] BROWN = 12'h960;  // body
  localparam [11:0] BLACK = 12'h000;  // outline / pupils
  localparam [11:0] WHITE = 12'hFFF;  // eye whites
  localparam [11:0] TRANS = 12'h001;

  // body_row[c] = 1 means this pixel is part of the Goomba (any color);
  // 0 means transparent. k_row / w_row override the default brown.
  reg [15:0] body_row, k_row, w_row;
  always @* begin
    case (r)
      4'd0:  begin body_row = 16'h0FF0; k_row = 16'h0FF0; w_row = 16'h0000; end
      4'd1:  begin body_row = 16'h3FFC; k_row = 16'h300C; w_row = 16'h0000; end
      4'd2:  begin body_row = 16'h7FFE; k_row = 16'h4002; w_row = 16'h0000; end
      4'd3:  begin body_row = 16'hFFFF; k_row = 16'h8001; w_row = 16'h0000; end
      4'd4:  begin body_row = 16'hFFFF; k_row = 16'h8001; w_row = 16'h300C; end
      4'd5:  begin body_row = 16'hFFFF; k_row = 16'h9009; w_row = 16'h2004; end
      4'd6:  begin body_row = 16'hFFFF; k_row = 16'h8001; w_row = 16'h300C; end
      4'd7:  begin body_row = 16'hFFFF; k_row = 16'h8001; w_row = 16'h0000; end
      4'd8:  begin body_row = 16'hFFFF; k_row = 16'h8001; w_row = 16'h0000; end
      4'd9:  begin body_row = 16'hFFFF; k_row = 16'h8001; w_row = 16'h0000; end
      4'd10: begin body_row = 16'h7FFE; k_row = 16'h4002; w_row = 16'h0000; end
      4'd11: begin body_row = 16'h3FFC; k_row = 16'h300C; w_row = 16'h0000; end
      4'd12: begin body_row = 16'h7FFE; k_row = 16'h581A; w_row = 16'h0000; end
      4'd13: begin body_row = 16'hFFFF; k_row = 16'h9009; w_row = 16'h0000; end
      4'd14: begin body_row = 16'hFFFF; k_row = 16'h9FF9; w_row = 16'h0000; end
      4'd15: begin body_row = 16'h700E; k_row = 16'h700E; w_row = 16'h0000; end
      default: begin body_row = 16'h0; k_row = 16'h0; w_row = 16'h0; end
    endcase
  end

  always @* begin
    if (!body_row[c])  color_data = TRANS;
    else if (k_row[c]) color_data = BLACK;
    else if (w_row[c]) color_data = WHITE;
    else               color_data = BROWN;
  end

endmodule
