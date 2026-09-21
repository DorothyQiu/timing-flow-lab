module user_mult #(
    parameter WIDTH = 8
)(
    input                   site_clk,
    input      [WIDTH-1:0]  req_data,
    output reg [WIDTH-1:0]  captured_data
);

always @(posedge site_clk)
    captured_data <= req_data;

endmodule