`timescale 1ns/1ps

module tb_demo2;

  reg         clk_in;
  reg         rst_n;
  reg [15:0]  a_in;
  reg [15:0]  b_in;
  wire [31:0] y_out;

  // DUT
  top_demo2 dut (
    .clk_in(clk_in),
    .rst_n (rst_n),
    .a_in  (a_in),
    .b_in  (b_in),
    .y_out (y_out)
  );

  // clock: 100MHz -> 10ns period
  initial begin
    clk_in = 1'b0;
    forever #5 clk_in = ~clk_in;
  end

  // reset + stimulus
  initial begin
    rst_n = 1'b0;
    a_in  = 16'd0;
    b_in  = 16'd0;

    // hold reset for a few cycles
    repeat (3) @(posedge clk_in);
    rst_n = 1'b1;

    // apply vectors
    @(posedge clk_in);
    a_in <= 16'd3;
    b_in <= 16'd7;

    @(posedge clk_in);
    a_in <= 16'd12;
    b_in <= 16'd11;

    @(posedge clk_in);
    a_in <= 16'd100;
    b_in <= 16'd20;

    // let pipeline settle a bit (station adds 1-cycle latency)
    repeat (5) @(posedge clk_in);

    $display("a_in=%0d b_in=%0d y_out=%0d", a_in, b_in, y_out);
    $finish;
  end

endmodule
