module six_bit_counter(
    input clk,
    input reset,
    output [5:0] count
);

    always @(negedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
        end else begin
            count <= count + 1;
        end
    end

endmodule