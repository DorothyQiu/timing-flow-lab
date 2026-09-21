module top_demo2 (
  input  wire        clk_in,
  input  wire        rst_n,
  input  wire [15:0] a_in,
  input  wire [15:0] b_in,
  output wire [31:0] y_out
);

  wire [15:0] a_s, b_s;

  station u_station (
    .clk  (clk_in),
    .rst_n(rst_n),
    .a_in (a_in),
    .b_in (b_in),
    .a_reg(a_s),
    .b_reg(b_s)
  );

  user_mult u_user (
    .clk  (clk_in),
    .rst_n(rst_n),
    .a    (a_s),
    .b    (b_s),
    .y    (y_out)
  );

endmodule
