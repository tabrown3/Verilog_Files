module fake_psx_two(
    input clk,
    output reg psx_clk = 1'b1,
    output reg cmd = 1'b1,
    output reg att = 1'b1
);

    localparam [3:0] STATE_SIZE = 4'h4;
    // STATES
    localparam [STATE_SIZE-1:0] STARTUP = 4'h0;
    localparam [STATE_SIZE-1:0] ATT_PULSE = 4'h1;
    localparam [STATE_SIZE-1:0] LOWER_ATT = 4'h2;
    localparam [STATE_SIZE-1:0] SEND_START_CMD = 4'h3;
    localparam [STATE_SIZE-1:0] AWAIT_START_ACK = 4'h4;
    localparam [STATE_SIZE-1:0] SEND_BEGIN_TX_CMD = 4'h5;
    localparam [STATE_SIZE-1:0] AWAIT_BEGIN_TX_ACK = 4'h6;
    localparam [STATE_SIZE-1:0] READ_PREAMBLE = 4'h7;
    localparam [STATE_SIZE-1:0] AWAIT_PREAMBLE_ACK = 4'h8;
    localparam [STATE_SIZE-1:0] READ_CONT_STATE_1 = 4'h9;
    localparam [STATE_SIZE-1:0] AWAIT_CONT_STATE_1_ACK = 4'ha;
    localparam [STATE_SIZE-1:0] READ_CONT_STATE_2 = 4'hb;
    localparam [STATE_SIZE-1:0] RAISE_ATT = 4'hc;
    localparam [STATE_SIZE-1:0] SEND_FAKE_START_CMD = 4'hd;
    localparam [STATE_SIZE-1:0] WAIT = 4'he;
    // END STATES

    reg [STATE_SIZE-1'b1:0] cur_state = STARTUP;
    reg [STATE_SIZE-1'b1:0] redirect_to;
    reg [31:0] time_to_wait = 0;
    reg [31:0] waited_time = 0;

    always @(negedge clk) begin
        case (cur_state)
            STARTUP: begin
                time_to_wait <= 16E6; // 8 seconds at 500ns per cycle
                waited_time <= waited_time + 1;
                if (waited_time >= time_to_wait) begin
                    cur_state <= ATT_PULSE;
                    redirect_to <= LOWER_ATT;
                    time_to_wait <= 0;
                    waited_time <= 0;
                end
            end
            ATT_PULSE: begin
                if (time_to_wait == 0) begin
                    att <= 1'b0;
                    time_to_wait <= 15; // 7.5us at 500ns per cycle
                end else begin
                    waited_time <= waited_time + 1;
                    if (waited_time >= time_to_wait) begin
                        att <= 1'b1;
                        cur_state <= redirect_to;
                        time_to_wait <= 0;
                        waited_time <= 0;
                    end
                end
            end
            LOWER_ATT: begin
                att <= 1'b0;
                cur_state <= SEND_START_CMD;
            end
        endcase
    end
endmodule