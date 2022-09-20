module fake_n64_controller(
    input data,
    input sample_clk,
    output derived_signal,
    output derived_clk
);
    localparam STATE_SIZE = 4; // bits
    // STATES
    localparam [STATE_SIZE-1:0] AWAITING_CMD = {STATE_SIZE{1'b0}};
    localparam [STATE_SIZE-1:0] PROCESSING_CMD = {{STATE_SIZE - 1{1'b0}}, 1'b1};
    localparam [STATE_SIZE-1:0] EXECUTING_CMD = {{STATE_SIZE - 2{1'b0}}, 2'b10};

    reg [STATE_SIZE-1:0] cur_state = AWAITING_CMD;
    reg reset = 1'b0;
    reg enable = 1'b1;
    reg [7:0] cmd = 8'hfe; // 0xFE is an unused command
    reg bit_cnt_clk = 1'b1;
    reg bit_cnt_reset = 1'b0;
    reg [5:0] bit_cnt = 6'h00;

    n_bit_counter BIT_CNT0(.clk(bit_cnt_clk), .reset(bit_cnt_reset), .count(bit_cnt));

    async_to_sync SYNC0(
        .data(data),
        .sample_clk(sample_clk),
        .reset(reset),
        .enable(enable),
        .derived_signal(derived_signal),
        .derived_clk(derived_clk)
    );

    always @(edge derived_clk) begin
        case (cur_state)
            AWAITING_CMD: begin
                if (!derived_clk) begin
                    cmd[6'h07 - bit_cnt] <= derived_signal;
                    if (bit_cnt == 6'h07) begin
                        cur_state <= PROCESSING_CMD;
                    end
                end
            end
            PROCESSING_CMD: begin
                case (cmd)
                    8'h00, 8'hff: begin // INFO, RESET
                        if (!derived_clk) begin
                            bit_cnt_reset <= 1'b1;
                            reset <= 1'b1;
                        end
                    end
                    8'h01: begin // BUTTON STATUS
                        if (!derived_clk) begin
                            bit_cnt_reset <= 1'b1;
                            reset <= 1'b1;
                        end
                    end
                    8'h02: begin // READ
                    end
                    8'h03: begin // WRITE
                    end
                endcase
            end
            EXECUTING_CMD: begin
                case (cmd)
                    8'h00: begin // INFO
                    end
                    8'h01: begin // BUTTON STATUS
                    end
                    8'h02: begin // READ
                    end
                    8'h03: begin // WRITE
                    end
                    8'hff: begin // RESET and INFO
                    end
                endcase
            end
        endcase
    end
endmodule