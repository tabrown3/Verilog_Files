module n_bit_circular_counter
#(
    parameter BIT_COUNT = 6
)
(
    input [BIT_COUNT-1:0] reset_at,
    input clk,
    output [BIT_COUNT-1:0] count
);

assign reset = count == reset_at;

n_bit_counter #(.BIT_COUNT(BIT_COUNT)) BIT_CNT0(
        .clk(clk),
        .reset(reset),
        .count(count)
);


endmodule