module generate_crc
#(
    parameter SEED = 8'h00
)
(
    input reset,
    input enable,
    input clk,
    input data,
    output [7:0] rem
);
    reg [7:0] window = SEED;

    assign rem = window;

    always @(edge clk) begin
        if (reset) begin
            window <= 8'h00;
        end else if (enable) begin
            if (!clk) begin
                window <= {
                    window[6]^window[7],
                    window[5],
                    window[4],
                    window[3],
                    window[2],
                    window[1]^window[7],
                    window[0],
                    data^window[7]
                };
            end
        end
    end
endmodule