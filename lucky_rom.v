`timescale 1ns / 1ps

// 16x16 "?" (lucky) block, Super Mario Bros style.
// Encoded as two 16-bit row masks per row: k_row[c]=1 means black pixel,
// w_row[c]=1 means white pixel, otherwise gold body.
module lucky_rom (
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

  localparam [11:0] GOLD  = 12'hFB0;  // yellow-gold body
  localparam [11:0] BLACK = 12'h000;
  localparam [11:0] WHITE = 12'hFFF;

  reg [15:0] k_row, w_row;
  always @* begin
    case (r)
      4'd0:  begin k_row = 16'hFFFF; w_row = 16'h0000; end  // top border
      4'd1:  begin k_row = 16'h8001; w_row = 16'h0000; end
      4'd2:  begin k_row = 16'hA005; w_row = 16'h0000; end  // top rivets
      4'd3:  begin k_row = 16'h87E1; w_row = 16'h0000; end  // top of "?" curve
      4'd4:  begin k_row = 16'h8811; w_row = 16'h07E0; end
      4'd5:  begin k_row = 16'h9009; w_row = 16'h0C30; end
      4'd6:  begin k_row = 16'h9009; w_row = 16'h0C30; end
      4'd7:  begin k_row = 16'h8801; w_row = 16'h0600; end  // curve sweeps down-left
      4'd8:  begin k_row = 16'h8401; w_row = 16'h0300; end
      4'd9:  begin k_row = 16'h8201; w_row = 16'h0180; end
      4'd10: begin k_row = 16'h8101; w_row = 16'h00C0; end
      4'd11: begin k_row = 16'h8081; w_row = 16'h0000; end  // gap above dot
      4'd12: begin k_row = 16'h8101; w_row = 16'h00C0; end  // the "?" dot
      4'd13: begin k_row = 16'hA105; w_row = 16'h00C0; end  // bottom rivets
      4'd14: begin k_row = 16'h8081; w_row = 16'h0000; end
      4'd15: begin k_row = 16'hFFFF; w_row = 16'h0000; end  // bottom border
      default: begin k_row = 16'h0000; w_row = 16'h0000; end
    endcase
  end

  always @* begin
    if (k_row[c])      color_data = BLACK;
    else if (w_row[c]) color_data = WHITE;
    else               color_data = GOLD;
  end

endmodule
