module n64_controller_rx
(
    input cur_operation,
    input data_rx,
    input sample_clk,
    output tx_handoff,
    output [7:0] cmd,
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
    wire read_ack_wire;
    reg read_ack = 1'b0;
    reg p_read_ack = 1'b0;

    n_bit_counter #(.BIT_COUNT(BIT_CNT_SIZE)) BIT_CNT0(
        .clk(~read_ack_wire),
        .reset(bit_cnt_reset_wire),
        .count(bit_cnt)
    );

    async_to_sync ASYNC0(
        .read_ack(read_ack_wire),
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
        .clk(~read_ack_wire),
        .data(derived_signal),
        .rem(rem)
    );

    assign cmd = inner_cmd;

    assign bit_cnt_reset_wire = (bit_cnt_reset^p_bit_cnt_reset) | cur_operation;
    assign crc_reset_wire = (crc_reset^p_crc_reset) | cur_operation;
    assign read_ack_wire = (read_ack^p_read_ack);
    always @(posedge sample_clk) begin
        p_bit_cnt_reset <= bit_cnt_reset;
        p_crc_reset <= crc_reset;
        p_read_ack <= read_ack;
    end

    always @(negedge sample_clk) begin
        if (!derived_clk) begin
            read_ack <= ~read_ack;
            if (cur_operation == 1'b0) begin
                if (bit_cnt >= 9'h08) begin
                    case (inner_cmd)
                        8'h00, 8'h01, 8'hff: begin // INFO, BUTTON STATUS, RESET
                            bit_cnt_reset <= ~bit_cnt_reset;
                        end
                        8'h02: begin // READ
                            if (bit_cnt < 9'd24) begin
                                address[6'd23 - bit_cnt] <= derived_signal;
                            end else begin
                                bit_cnt_reset <= ~bit_cnt_reset;
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
                                crc_reset <= ~crc_reset;
                            end
                        end
                        default: begin
                            inner_cmd <= 8'h00;
                        end
                    endcase
                end else begin
                    inner_cmd[9'h07 - bit_cnt] <= derived_signal;
                end
            end
        end
    end
endmodule