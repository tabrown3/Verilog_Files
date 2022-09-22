module fake_n64_controller_rx
(
    input cur_operation,
    input data_rx,
    input sample_clk,
    output reg tx_handoff = 1'b0,
    output reg [7:0] cmd = 8'hfe,
    output reg [15:0] address
);
    wire derived_signal;
    wire derived_clk;
    reg bit_cnt_reset = 1'b0;
    wire [5:0] bit_cnt;

    n_bit_counter BIT_CNT0(.clk(derived_clk), .reset(bit_cnt_reset), .count(bit_cnt));

    async_to_sync ASYNC0(
        .cur_operation(cur_operation),
        .data(data_rx),
        .sample_clk(sample_clk),
        .derived_signal(derived_signal),
        .derived_clk(derived_clk)
    );

    always @(edge derived_clk) begin
        if (derived_clk && bit_cnt_reset) begin
            bit_cnt_reset <= 1'b0;
        end

        if (!derived_clk) begin
            if (bit_cnt == 6'h08) begin
                case (cmd)
                    8'h00, 8'h01, 8'hff: begin // INFO, BUTTON STATUS, RESET
                        if (!derived_clk) begin
                            bit_cnt_reset <= 1'b1;
                            tx_handoff <= ~tx_handoff;
                        end
                    end
                    8'h02, 8'h03: begin // READ, WRITE
                        if (!derived_clk) begin
                            address[6'h17 - bit_cnt] <= derived_signal; // 23 - bit cnt
                        end
                    end
                endcase
            end else begin
                cmd[6'h07 - bit_cnt] <= derived_signal;
            end
        end
    end
endmodule