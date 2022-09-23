module generate_crc
#(
    parameter SEED = 8'h00
)
(
    input reset,
    input [7:0] reset_to,
    input enable,
    input clk,
    input data,
    output [7:0] rem
);
    reg [7:0] window = SEED;

    assign rem = window;

    always @(negedge clk, posedge reset) begin
        if (reset) begin
            if (reset_to) begin
                window <= reset_to;
            end else begin
                window <= 8'h00;
            end
        end else if (enable) begin
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
endmodule