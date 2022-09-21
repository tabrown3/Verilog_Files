module fake_n64_controller_rx
#(
    parameter READ_STATE_SIZE = 4, // bits
    parameter [READ_STATE_SIZE-1:0] AWAITING_CMD = {READ_STATE_SIZE{1'b0}},
    parameter [READ_STATE_SIZE-1:0] RESPONDING_TO_INFO = {{READ_STATE_SIZE - 1{1'b0}}, 1'b1},
    parameter [READ_STATE_SIZE-1:0] RESPONDING_TO_STATUS = {{READ_STATE_SIZE - 2{1'b0}}, 2'b10},
    parameter [READ_STATE_SIZE-1:0] READING_ADDRESS = {{READ_STATE_SIZE - 2{1'b0}}, 2'b11},
    parameter [READ_STATE_SIZE-1:0] PREP_INFO_RESPONSE = {{READ_STATE_SIZE - 3{1'b0}}, 3'b100},
    parameter [READ_STATE_SIZE-1:0] PREP_STATUS_RESPONSE = {{READ_STATE_SIZE - 3{1'b0}}, 3'b101}
)
(
    input data_rx,
    input sample_clk,
    input cur_write_state,
    output reg [READ_STATE_SIZE-1:0] cur_read_state = AWAITING_CMD
);
    // STATES

    wire derived_signal;
    wire derived_clk;
    reg [7:0] cmd = 8'hfe; // 0xFE is an unused command
    reg bit_cnt_reset = 1'b0;
    wire [5:0] bit_cnt;
    reg [15:0] address;

    n_bit_counter BIT_CNT0(.clk(derived_clk), .reset(bit_cnt_reset), .count(bit_cnt));

    async_to_sync ASYNC0(
        .data(data_rx),
        .sample_clk(sample_clk),
        .derived_signal(derived_signal),
        .derived_clk(derived_clk)
    );

    always @(edge derived_clk) begin
        case (cur_read_state)
            AWAITING_CMD: begin
                if (!derived_clk) begin
                    if (bit_cnt == 6'h08) begin
                        case (cmd)
                            8'h00, 8'hff: begin // INFO, RESET
                                if (!derived_clk) begin
                                    bit_cnt_reset <= 1'b1;
                                    cur_read_state <= PREP_INFO_RESPONSE;
                                end
                            end
                            8'h01: begin // BUTTON STATUS
                                if (!derived_clk) begin
                                    bit_cnt_reset <= 1'b1;
                                    cur_read_state <= PREP_STATUS_RESPONSE;
                                end
                            end
                            8'h02, 8'h03: begin // READ, WRITE
                                if (!derived_clk) begin
                                    address[6'h17 - bit_cnt] <= derived_signal; // 23 - bit cnt
                                    cur_read_state <= READING_ADDRESS;
                                end
                            end
                        endcase
                    end else begin
                        cmd[6'h07 - bit_cnt] <= derived_signal;
                    end
                end
            end
            PREP_INFO_RESPONSE: begin
                if (!derived_clk) begin
                    cur_read_state <= AWAITING_CMD;
                end else begin
                    bit_cnt_reset <= 1'b0;
                end
            end
            PREP_STATUS_RESPONSE: begin
                if (!derived_clk) begin
                    cur_read_state <= AWAITING_CMD;
                end else begin
                    bit_cnt_reset <= 1'b0;
                end
            end
            RESPONDING_TO_INFO: begin
            end
            RESPONDING_TO_STATUS: begin
            end
            READING_ADDRESS: begin
            end
        endcase
    end
endmodule