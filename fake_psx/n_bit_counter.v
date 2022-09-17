module n_bit_counter
#(
    parameter BIT_COUNT = 6
)
(
    input clk,
    input reset,
    output reg [BIT_COUNT - 1:0] count = 0
);

    always @(negedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
        end else begin
            count <= count + 1;
        end
    end

endmodule