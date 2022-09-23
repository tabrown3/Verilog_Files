`timescale 1us/100ns
module tb_n_bit_circular_counter();

    localparam BIT_COUNT = 6;

    reg clk = 1'b1;
    reg [BIT_COUNT-1:0] reset_at;
    wire [BIT_COUNT-1:0] count;

    n_bit_circular_counter CCNT0(
        .clk(clk),
        .reset_at(reset_at),
        .count(count)
    );

    initial begin
        #1;
        reset_at = 5;
        repeat(25) #1 clk = !clk;
    end
endmodule