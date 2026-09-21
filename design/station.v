module station #(
    parameter WIDTH = 8
)(
    input                  clk,
    input      [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] req_data
);

always @(posedge clk)
    req_data <= data_in;

endmodule