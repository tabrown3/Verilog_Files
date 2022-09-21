module fake_n64_controller(
    input data_rx,
    input sample_clk,
    output data_tx
);
    localparam READ_STATE_SIZE = 4;
    localparam WRITE_STATE_SIZE = 4;

    wire [READ_STATE_SIZE-1:0] cur_read_state;
    wire [WRITE_STATE_SIZE-1:0] cur_write_state;

    fake_n64_controller_rx
    #(
        .READ_STATE_SIZE(READ_STATE_SIZE)
    ) RX0 (
        .data_rx(data_rx),
        .sample_clk(sample_clk),
        .cur_write_state(cur_write_state),
        .cur_read_state(cur_read_state)
    );

    localparam LEVEL_WIDTH = 4'h2; // in clk cycles
    localparam BIT_WIDTH = 4'h4*LEVEL_WIDTH; // in clk cycles

    // tx_byte_buffer <= 24'h050000; // INFO - OEM controller
    // tx_byte_buffer <= 32'h00000000; // STATUS - no buttons

    reg level_cnt_reset = 1'b0;
    wire [5:0] level_cnt;
    reg [31:0] tx_byte_buffer;
    reg [BIT_WIDTH - 1:0] tx_bit_buffer;

    n_bit_counter LEVEL_CNT0(.clk(sample_clk), .reset(level_cnt_reset), .count(level_cnt));

    always @(edge sample_clk) begin
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