`timescale 1ns / 1ps

// 32x16 cloud sprite. Outputs the sentinel color 12'h001 outside the cloud
// silhouette so the caller can treat it as transparent.
module cloud_rom (
    input  wire        clk,
    input  wire [9:0]  row,
    input  wire [9:0]  col,
    output reg  [11:0] color_data
);

  reg [3:0] r;
  reg [4:0] c;
  always @(posedge clk) begin
    r <= row[3:0];
    c <= col[4:0];
  end

  localparam [11:0] BLACK = 12'h000;
  localparam [11:0] WHITE = 12'hFFF;
  localparam [11:0] TRANS = 12'h001;

  reg [31:0] k_row, w_row;
  always @* begin
    case (r)
      4'd0:  begin k_row = 32'h00000000; w_row = 32'h00000000; end
      4'd1:  begin k_row = 32'h007FFE00; w_row = 32'h00000000; end
      4'd2:  begin k_row = 32'h038001C0; w_row = 32'h007FFE00; end
      4'd3:  begin k_row = 32'h0C000030; w_row = 32'h03FFFFC0; end
      4'd4:  begin k_row = 32'h10000008; w_row = 32'h0FFFFFF0; end
      4'd5:  begin k_row = 32'h20000004; w_row = 32'h1FFFFFF8; end
      4'd6:  begin k_row = 32'h40000002; w_row = 32'h3FFFFFFC; end
      4'd7:  begin k_row = 32'h40000002; w_row = 32'h3FFFFFFC; end
      4'd8:  begin k_row = 32'h40000002; w_row = 32'h3FFFFFFC; end
      4'd9:  begin k_row = 32'h40000002; w_row = 32'h3FFFFFFC; end
      4'd10: begin k_row = 32'h40000002; w_row = 32'h3FFFFFFC; end
      4'd11: begin k_row = 32'h20000004; w_row = 32'h1FFFFFF8; end
      4'd12: begin k_row = 32'h10000008; w_row = 32'h0FFFFFF0; end
      4'd13: begin k_row = 32'h0C000030; w_row = 32'h03FFFFC0; end
      4'd14: begin k_row = 32'h038001C0; w_row = 32'h007FFE00; end
      4'd15: begin k_row = 32'h007FFE00; w_row = 32'h00000000; end
      default: begin k_row = 32'h0; w_row = 32'h0; end
    endcase
  end

  always @* begin
    if (k_row[c])      color_data = BLACK;
    else if (w_row[c]) color_data = WHITE;
    else               color_data = TRANS;
  end

endmodule
