module fake_n64_controller(
    input data,
    input sample_clk,
    output derived_signal,
    output derived_clk
);
    localparam STATE_SIZE = 4; // bits
    // STATES
    localparam [STATE_SIZE-1:0] AWAITING_CMD = {STATE_SIZE{1'b0}};
    localparam [STATE_SIZE-1:0] RESPONDING_TO_INFO = {{STATE_SIZE - 1{1'b0}}, 1'b1};
    localparam [STATE_SIZE-1:0] RESPONDING_TO_STATUS = {{STATE_SIZE - 2{1'b0}}, 2'b10};
    localparam [STATE_SIZE-1:0] READING_ADDRESS = {{STATE_SIZE - 2{1'b0}}, 2'b11};

    reg [STATE_SIZE-1:0] cur_state = AWAITING_CMD;
    reg reset = 1'b0;
    reg enable = 1'b1;
    reg [7:0] cmd = 8'hfe; // 0xFE is an unused command
    reg bit_cnt_reset = 1'b0;
    wire [5:0] bit_cnt;
    reg [15:0] address;

    n_bit_counter BIT_CNT0(.clk(derived_clk), .reset(bit_cnt_reset), .count(bit_cnt));

    async_to_sync SYNC0(
        .data(data),
        .sample_clk(sample_clk),
        .derived_signal(derived_signal),
        .derived_clk(derived_clk)
    );

    always @(edge derived_clk) begin
        case (cur_state)
            AWAITING_CMD: begin
                if (!derived_clk) begin
                    if (bit_cnt == 6'h08) begin
                        case (cmd)
                            8'h00, 8'hff: begin // INFO, RESET
                                if (!derived_clk) begin
                                    bit_cnt_reset <= 1'b1;
                                    cur_state <= RESPONDING_TO_INFO;
                                end
                            end
                            8'h01: begin // BUTTON STATUS
                                if (!derived_clk) begin
                                    bit_cnt_reset <= 1'b1;
                                    cur_state <= RESPONDING_TO_STATUS;
                                end
                            end
                            8'h02, 8'h03: begin // READ, WRITE
                                if (!derived_clk) begin
                                    address[6'h17 - bit_cnt] <= derived_signal; // 23 - bit cnt
                                    cur_state <= READING_ADDRESS;
                                end
                            end
                        endcase
                    end else begin
                        cmd[6'h07 - bit_cnt] <= derived_signal;
                    end
                end
            end
            RESPONDING_TO_INFO: begin
                if (!derived_clk) begin
                    bit_cnt_reset <= 1'b0;
                end
            end
            RESPONDING_TO_STATUS: begin
                if (!derived_clk) begin
                    bit_cnt_reset <= 1'b0;
                end
            end
            READING_ADDRESS: begin
            end
        endcase
    end
endmodule