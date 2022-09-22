module fake_n64_controller_tx(
    input sample_clk,
    input cur_operation,
    input [7:0] cmd,
    output reg rx_handoff = 1'b0,
    output reg data_tx
);
    localparam LEVEL_WIDTH = 4'h2; // in clk cycles
    localparam BIT_WIDTH = 4'h4*LEVEL_WIDTH; // in clk cycles
    localparam STOP_BIT = {{LEVEL_WIDTH{1'b0}}, {LEVEL_WIDTH{1'b0}}, {LEVEL_WIDTH{1'b1}},
        {LEVEL_WIDTH{1'bz}}}; // L,L,H,Z

    localparam STATE_SIZE = 4; // bits
    // STATES
    localparam [STATE_SIZE-1:0] PREPPING_RESPONSE = {STATE_SIZE{1'b0}};
    localparam [STATE_SIZE-1:0] SENDING_LEVELS = {{STATE_SIZE - 1{1'b0}}, 1'b1};
    localparam [STATE_SIZE-1:0] SENDING_STOP = {{STATE_SIZE - 2{1'b0}}, 2'b10};

    reg [STATE_SIZE - 1:0] cur_state = PREPPING_RESPONSE;
    reg level_cnt_reset = 1'b0;
    reg level_cnt_clk = 1'b1;
    wire [2:0] level_cnt;
    reg bit_cnt_reset = 1'b0;
    reg bit_cnt_clk = 1'b1;
    wire [5:0] bit_cnt;
    reg [31:0] tx_byte_buffer;
    reg [5:0] tx_byte_buffer_length;
    reg [BIT_WIDTH - 1:0] tx_bit_buffer;

    n_bit_counter #(.BIT_COUNT(3)) LEVEL_CNT0(
        .clk(level_cnt_clk),
        .reset(1'b0),
        .count(level_cnt)
    );
    n_bit_counter BIT_CNT0(.clk(bit_cnt_clk), .reset(bit_cnt_reset), .count(bit_cnt));

    always @(edge sample_clk) begin
        if (cur_operation == 1'b1) begin // Tx   
            if (sample_clk) begin
                level_cnt_clk <= 1'b1;
                level_cnt_reset <= 1'b0;
                bit_cnt_clk <= 1'b1;
                bit_cnt_reset <= 1'b0;
            end

            if (!sample_clk) begin
                if (cur_state == PREPPING_RESPONSE) begin
                    case (cmd)
                        8'h00, 8'hff: begin
                            tx_byte_buffer <= 24'h050000; // INFO - OEM controller
                            tx_byte_buffer_length <= 6'd24;
                            cur_state <= SENDING_LEVELS;

                            tx_bit_buffer <= wire_encoding(1'b0); // set levels for first bit
                        end
                        8'h01: begin
                            tx_byte_buffer <= 32'h00000000; // STATUS - buttons/analog sticks
                            tx_byte_buffer_length <= 6'd32;
                            cur_state <= SENDING_LEVELS;

                            tx_bit_buffer <= wire_encoding(1'b0); // set levels for first bit
                        end
                        8'h02: begin // READ
                        end
                        8'h03: begin // WRITE
                        end
                    endcase
                end else if (cur_state == SENDING_LEVELS) begin
                    if (level_cnt == BIT_WIDTH - 1) begin // if reached the end of a bit
                        bit_cnt_clk <= 1'b0; // increment bit count

                        if (bit_cnt == tx_byte_buffer_length + 1) begin
                            rx_handoff <= ~rx_handoff;
                        end // if all data bits have been transmitted
                        else if (bit_cnt == tx_byte_buffer_length) begin
                            tx_bit_buffer <= STOP_BIT;
                            level_cnt_clk <= 1'b0;
                        end else begin // otherwise load the next data bit
                            tx_bit_buffer <= wire_encoding(
                                tx_byte_buffer[tx_byte_buffer_length - 2 - bit_cnt]
                            );
                            // TODO: what even is this line doing? It's assigning a bits to a 1 bit reg
                            data_tx <= tx_byte_buffer[tx_byte_buffer_length - 2 - bit_cnt] ? 8'h03 : 8'h3f;
                            level_cnt_clk <= 1'b0;
                        end
                    end else begin // otherwise transmit the next level in the bit
                        data_tx <= tx_bit_buffer[BIT_WIDTH - 1 - level_cnt];
                        level_cnt_clk <= 1'b0; // and increment level count
                    end
                end
            end
        end
    end

    // LEVEL in this context is physical HIGH or LOW. In the Joybus protocol, bits can
    //  be broken into as many as 4 LEVELs. For instance, logical "0" is LOW-LOW-LOW-HIGH.
    //  LEVEL_WIDTH is the number of cycles each LEVEL remains constant. If LEVEL_WIDTH = 2,
    //  a logical "0" would take 8 clk cycles to transmit: LOW (2 cycles), LOW (2 cycles),
    //  LOW (2 cycles), HIGH (2 cycles). Therefore the BIT_WIDTH is 8 clk cycles, because
    //  it takes 8 cycles to fully transmit a single bit.
    function [BIT_WIDTH - 1:0] wire_encoding (input logic_bit);
        case (logic_bit)
            1'b0: begin // logical 0
                wire_encoding = {{LEVEL_WIDTH{1'b0}}, {LEVEL_WIDTH{1'b0}},
                    {LEVEL_WIDTH{1'b0}}, {LEVEL_WIDTH{1'b1}}}; // L,L,L,H
            end
            1'b1: begin // logical 1
                wire_encoding = {{LEVEL_WIDTH{1'b0}}, {LEVEL_WIDTH{1'b1}},
                    {LEVEL_WIDTH{1'b1}}, {LEVEL_WIDTH{1'b1}}}; // L,H,H,H
            end
        endcase
    endfunction
endmodule