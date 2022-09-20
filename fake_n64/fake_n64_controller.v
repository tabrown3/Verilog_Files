module fake_n64_controller(
    input data_rx,
    input sample_clk,
    output data_tx
);
    localparam LEVEL_WIDTH = 4'h2; // in clk cycles
    localparam BIT_WIDTH = 4'h4*LEVEL_WIDTH; // in clk cycles

    localparam STATE_SIZE = 4; // bits
    // STATES
    localparam [STATE_SIZE-1:0] AWAITING_CMD = {STATE_SIZE{1'b0}};
    localparam [STATE_SIZE-1:0] RESPONDING_TO_INFO = {{STATE_SIZE - 1{1'b0}}, 1'b1};
    localparam [STATE_SIZE-1:0] RESPONDING_TO_STATUS = {{STATE_SIZE - 2{1'b0}}, 2'b10};
    localparam [STATE_SIZE-1:0] READING_ADDRESS = {{STATE_SIZE - 2{1'b0}}, 2'b11};
    localparam [STATE_SIZE-1:0] PREP_INFO_RESPONSE = {{STATE_SIZE - 3{1'b0}}, 3'b100};
    localparam [STATE_SIZE-1:0] PREP_STATUS_RESPONSE = {{STATE_SIZE - 3{1'b0}}, 3'b101};

    reg [STATE_SIZE-1:0] cur_state = AWAITING_CMD;
    wire derived_signal;
    wire derived_clk;
    reg [7:0] cmd = 8'hfe; // 0xFE is an unused command
    reg bit_cnt_reset = 1'b0;
    wire [5:0] bit_cnt;
    reg [15:0] address;
    reg [31:0] tx_byte_buffer;
    reg [BIT_WIDTH - 1:0] tx_bit_buffer;

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
                                    cur_state <= PREP_INFO_RESPONSE;
                                end
                            end
                            8'h01: begin // BUTTON STATUS
                                if (!derived_clk) begin
                                    bit_cnt_reset <= 1'b1;
                                    cur_state <= PREP_STATUS_RESPONSE;
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
            PREP_INFO_RESPONSE: begin
                bit_cnt_reset <= 1'b0;
                if (!derived_clk) begin
                    tx_byte_buffer <= 24'h050000; // OEM controller
                end
            end
            PREP_STATUS_RESPONSE: begin
                bit_cnt_reset <= 1'b0;
                if (!derived_clk) begin
                    tx_byte_buffer <= 32'h00000000; // no buttons pressed, analog stick at center
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


    // LEVEL in this context is physical HIGH or LOW. In the Joybus protocol, bits can
    //  be broken into as many as 4 LEVELs. For instance, logical "0" is LOW-LOW-LOW-HIGH.
    //  LEVEL_WIDTH is the number of cycles each LEVEL remains constant. If LEVEL_WIDTH = 2,
    //  a logical "0" would take 8 clk cycles to transmit: LOW (2 cycles), LOW (2 cycles),
    //  LOW (2 cycles), HIGH (2 cycles). Therefore the BIT_WIDTH is 8 clk cycles, because
    //  it takes 8 cycles to fully transmit a single bit.
    function [BIT_WIDTH - 1:0] wire_encoding (input [1:0] logic_bit);
        case (logic_bit)
            2'b00: begin // logical 0
                wire_encoding = {{LEVEL_WIDTH{1'b0}}, {LEVEL_WIDTH{1'b0}},
                    {LEVEL_WIDTH{1'b0}}, {LEVEL_WIDTH{1'b1}}}; // L,L,L,H
            end
            2'b01: begin // logical 1
                wire_encoding = {{LEVEL_WIDTH{1'b0}}, {LEVEL_WIDTH{1'b1}},
                    {LEVEL_WIDTH{1'b1}}, {LEVEL_WIDTH{1'b1}}}; // L,H,H,H
            end
            2'b10: begin // console STOP bit
                wire_encoding = {{LEVEL_WIDTH{1'b0}}, {LEVEL_WIDTH{1'b1}},
                    {LEVEL_WIDTH{1'b1}}, {LEVEL_WIDTH{1'bz}}}; // L,H,H,Z
            end
            2'b11: begin // controller STOP bit
                wire_encoding = {{LEVEL_WIDTH{1'b0}}, {LEVEL_WIDTH{1'b0}},
                    {LEVEL_WIDTH{1'b1}}, {LEVEL_WIDTH{1'bz}}}; // L,L,H,Z
            end
            default: begin
                wire_encoding = {LEVEL_WIDTH{1'b1}}; // H,H,H,H - might regret this...
            end
        endcase
    endfunction
endmodule