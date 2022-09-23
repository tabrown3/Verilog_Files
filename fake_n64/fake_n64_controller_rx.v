module fake_n64_controller_rx
(
    input cur_operation,
    input data_rx,
    input sample_clk,
    output reg tx_handoff = 1'b0,
    output reg [7:0] cmd = 8'hfe,
    output reg [15:0] address = 16'h0000,
    output wire [7:0] crc
);
    localparam BIT_CNT_SIZE = 9;

    wire derived_signal;
    wire derived_clk;
    reg bit_cnt_reset = 1'b0;
    wire [BIT_CNT_SIZE-1:0] bit_cnt;
    reg crc_reset = 1'b0;
    reg crc_enable = 1'b0;

    n_bit_counter #(.BIT_COUNT(BIT_CNT_SIZE)) BIT_CNT0(
        .clk(derived_clk),
        .reset(bit_cnt_reset),
        .count(bit_cnt)
    );

    async_to_sync ASYNC0(
        .cur_operation(cur_operation),
        .data(data_rx),
        .sample_clk(sample_clk),
        .derived_signal(derived_signal),
        .derived_clk(derived_clk)
    );

    generate_crc CRC0(
        .reset(crc_reset),
        .enable(crc_enable),
        .clk(derived_clk),
        .data(derived_signal),
        .rem(crc)
    );

    always @(edge derived_clk) begin
        if (derived_clk) begin
            bit_cnt_reset <= 1'b0;
        end

        if (!derived_clk) begin
            if (bit_cnt >= 9'h08) begin
                case (cmd)
                    8'h00, 8'h01, 8'hff: begin // INFO, BUTTON STATUS, RESET
                        if (!derived_clk) begin
                            bit_cnt_reset <= 1'b1;
                            tx_handoff <= ~tx_handoff;
                        end
                    end
                    8'h02: begin // READ
                        if (bit_cnt < 9'd24) begin
                            address[6'd23 - bit_cnt] <= derived_signal;
                        end else begin
                            bit_cnt_reset <= 1'b1;
                            tx_handoff <= ~tx_handoff;
                        end
                    end
                    8'h03: begin // WRITE
                        if (!derived_clk) begin
                            if (bit_cnt < 9'd24) begin
                                address[6'd23 - bit_cnt] <= derived_signal;

                                if (bit_cnt == 9'd23) begin
                                    crc_enable <= 1'b1;
                                end
                            end else if (bit_cnt == 9'd279) begin
                                crc_enable <= 1'b0;
                            end else if (bit_cnt == 9'd280) begin
                                bit_cnt_reset <= 1'b1;
                                tx_handoff <= ~tx_handoff;
                            end
                        end
                    end
                endcase
            end else begin
                cmd[9'h07 - bit_cnt] <= derived_signal;
            end
        end
    end
endmodule