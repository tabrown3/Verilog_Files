module n64_controller_rx
(
    input cur_operation,
    input data_rx,
    input sample_clk,
    output tx_handoff,
    output reg [7:0] cmd = 8'h00,
    output reg [15:0] address = 16'h0000,
    output reg [7:0] crc
);
    localparam BIT_CNT_SIZE = 9;

    wire derived_signal;
    wire derived_clk;
    wire bit_cnt_reset_wire;
    reg bit_cnt_reset = 1'b0;
    reg p_bit_cnt_reset = 1'b0;
    wire [BIT_CNT_SIZE-1:0] bit_cnt;
    wire crc_reset_wire;
    reg crc_reset = 1'b0;
    reg p_crc_reset = 1'b0;
    reg crc_enable = 1'b0;
    wire [7:0] rem;
    reg [7:0] inner_cmd = 8'h00;

    n_bit_counter #(.BIT_COUNT(BIT_CNT_SIZE)) BIT_CNT0(
        .clk(derived_clk),
        .reset(bit_cnt_reset_wire),
        .count(bit_cnt)
    );

    async_to_sync ASYNC0(
        .cur_operation(cur_operation),
        .data(data_rx),
        .sample_clk(sample_clk),
        .derived_signal(derived_signal),
        .derived_clk(derived_clk),
        .tx_handoff(tx_handoff)
    );

    generate_crc CRC0(
        .reset(crc_reset_wire),
        .enable(crc_enable),
        .clk(derived_clk),
        .data(derived_signal),
        .rem(rem)
    );

    assign bit_cnt_reset_wire = (bit_cnt_reset^p_bit_cnt_reset) | cur_operation;
    assign crc_reset_wire = (crc_reset^p_crc_reset) | cur_operation;
    always @(posedge derived_clk) begin
        p_bit_cnt_reset <= bit_cnt_reset;
        p_crc_reset <= crc_reset;
    end

    always @(negedge derived_clk) begin
        if (bit_cnt >= 9'h08) begin
            case (inner_cmd)
                8'h00, 8'h01, 8'hff: begin // INFO, BUTTON STATUS, RESET
                    bit_cnt_reset <= ~bit_cnt_reset;
                    cmd <= inner_cmd;
                    inner_cmd <= 8'h00;
                end
                8'h02: begin // READ
                    if (bit_cnt < 9'd24) begin
                        address[6'd23 - bit_cnt] <= derived_signal;
                    end else begin
                        bit_cnt_reset <= ~bit_cnt_reset;
                        cmd <= inner_cmd;
                        inner_cmd <= 8'h00;
                    end
                end
                8'h03: begin // WRITE
                    if (bit_cnt < 9'd24) begin
                        address[6'd23 - bit_cnt] <= derived_signal;

                        if (bit_cnt == 9'd23) begin
                            crc_enable <= 1'b1;
                        end
                    end else if (bit_cnt == 9'd279) begin
                        crc_enable <= 1'b0;
                    end else if (bit_cnt == 9'd280) begin
                        crc <= rem;
                        bit_cnt_reset <= ~bit_cnt_reset;
                        cmd <= inner_cmd;
                        inner_cmd <= 8'h00;
                        crc_reset <= ~crc_reset;
                    end
                end
                default: begin
                    inner_cmd <= 8'h00;
                    cmd <= 8'h00;
                end
            endcase
        end else begin
            inner_cmd[9'h07 - bit_cnt] <= derived_signal;
        end
    end
endmodule