module fake_n64_controller(
    input data_rx,
    input sample_clk,
    output data_tx
);
    localparam STATE_SIZE = 4; // bits
    // STATES
    localparam [STATE_SIZE-1:0] AWAITING_CMD = {STATE_SIZE{1'b0}};
    localparam [STATE_SIZE-1:0] RESPONDING_TO_INFO = {{STATE_SIZE - 1{1'b0}}, 1'b1};
    localparam [STATE_SIZE-1:0] RESPONDING_TO_STATUS = {{STATE_SIZE - 2{1'b0}}, 2'b10};
    localparam [STATE_SIZE-1:0] READING_ADDRESS = {{STATE_SIZE - 2{1'b0}}, 2'b11};

    reg [STATE_SIZE-1:0] cur_state = AWAITING_CMD;
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
                bit_cnt_reset <= 1'b0;
                if (!derived_clk) begin
                    
                end
            end
            RESPONDING_TO_STATUS: begin
                bit_cnt_reset <= 1'b0;
                if (!derived_clk) begin
                    
                end
            end
            READING_ADDRESS: begin
            end
        endcase
    end

    localparam BIT_WIDTH = 2;
    function [7:0] wire_encoding (input [1:0] logic_bit);
        case (logic_bit)
            2'b00: begin // logical 0
                wire_encoding = {{BIT_WIDTH{1'b0}}, {BIT_WIDTH{1'b0}},
                    {BIT_WIDTH{1'b0}}, {BIT_WIDTH{1'b1}}}; // 0001
            end
            2'b01: begin // logical 1
                wire_encoding = {{BIT_WIDTH{1'b0}}, {BIT_WIDTH{1'b1}},
                    {BIT_WIDTH{1'b1}}, {BIT_WIDTH{1'b1}}}; // 0111
            end
            2'b10: begin // console STOP bit
                wire_encoding = {{BIT_WIDTH{1'b0}}, {BIT_WIDTH{1'b1}},
                    {BIT_WIDTH{1'b1}}, {BIT_WIDTH{1'bz}}}; // 011z
            end
            2'b11: begin // controller STOP bit
                wire_encoding = {{BIT_WIDTH{1'b0}}, {BIT_WIDTH{1'b0}},
                    {BIT_WIDTH{1'b1}}, {BIT_WIDTH{1'bz}}}; // 001z
            end
            default: begin
                wire_encoding = {BIT_WIDTH{1'b1}}; // 1111 - might regret this...
            end
        endcase
    endfunction
endmodule