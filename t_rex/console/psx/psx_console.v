module psx_console
#(
    parameter [31:0] BOOT_TIME = 4E6 // 2 seconds at 500ns per cycle
)
(
    input clk,
    input data,
    input ack,
    output reg psx_clk = 1'b1,
    output reg cmd = 1'b1,
    output reg att = 1'b1,
    output [15:0] button_state,
    output [31:0] stick_state
);

    localparam [3:0] STATE_SIZE = 4'h4;
    // STATES
    localparam [STATE_SIZE-1:0] STARTUP = 4'h0;
    localparam [STATE_SIZE-1:0] ATT_PULSE = 4'h1;
    localparam [STATE_SIZE-1:0] LOWER_ATT = 4'h2;
    localparam [STATE_SIZE-1:0] SEND_START_CMD = 4'h3;
    localparam [STATE_SIZE-1:0] AWAIT_ACK = 4'h4;
    localparam [STATE_SIZE-1:0] SEND_BEGIN_TX_CMD = 4'h5;
    localparam [STATE_SIZE-1:0] READ_PREAMBLE = 4'h6;
    localparam [STATE_SIZE-1:0] READ_BTN_STATE_1 = 4'h7;
    localparam [STATE_SIZE-1:0] READ_BTN_STATE_2 = 4'h8;
    localparam [STATE_SIZE-1:0] READ_STICK_STATE_RX = 4'h9;
    localparam [STATE_SIZE-1:0] READ_STICK_STATE_RY = 4'ha;
    localparam [STATE_SIZE-1:0] READ_STICK_STATE_LX = 4'hb;
    localparam [STATE_SIZE-1:0] READ_STICK_STATE_LY = 4'hc;
    localparam [STATE_SIZE-1:0] RAISE_ATT = 4'hd;

    // END STATES
    localparam [7:0] NO_OP = 8'h00;
    localparam [7:0] START_CMD = 8'h01;
    localparam [7:0] BEGIN_TX_CMD = 8'h42;

    reg [STATE_SIZE-1'b1:0] cur_state = STARTUP;
    reg [STATE_SIZE-1'b1:0] redirect_to;
    reg [31:0] time_to_wait = 0;
    reg [31:0] waited_time = 0;
    reg [7:0] bit_cnt = 8'h00;
    reg [7:0] btn_state_1 = 8'hff;
    reg [7:0] btn_state_2 = 8'hff;
    reg [7:0] stick_state_rx = 8'h80;
    reg [7:0] stick_state_ry = 8'h80;
    reg [7:0] stick_state_lx = 8'h80;
    reg [7:0] stick_state_ly = 8'h80;

    assign button_state = {btn_state_1, btn_state_2};
    assign stick_state = {stick_state_rx, stick_state_ry, stick_state_lx, stick_state_ly};

    always @(negedge clk) begin
        case (cur_state)
            STARTUP: begin
                if (time_to_wait == 0) begin
                    time_to_wait <= BOOT_TIME;
                    waited_time <= 0;
                end else begin
                    waited_time <= waited_time + 1;
                    if (waited_time >= time_to_wait) begin
                        cur_state <= ATT_PULSE;
                        redirect_to <= LOWER_ATT;
                        time_to_wait <= 0;
                        waited_time <= 0;
                    end
                end
            end
            ATT_PULSE: begin
                if (time_to_wait == 0) begin
                    att <= 1'b0;
                    time_to_wait <= 32E3;
                    waited_time <= 0;
                end else begin
                    waited_time <= waited_time + 1;
                    if (waited_time >= 15) begin
                        if (waited_time < time_to_wait) begin
                            att <= 1'b1;
                        end else begin
                            cur_state <= redirect_to;
                            time_to_wait <= 0;
                            waited_time <= 0;
                        end
                    end
                end
            end
            LOWER_ATT: begin
                att <= 1'b0;
                cur_state <= SEND_START_CMD;
            end
            SEND_START_CMD: begin
                tx_cmd(START_CMD, AWAIT_ACK, SEND_BEGIN_TX_CMD, 76);
            end
            AWAIT_ACK: begin
                if (time_to_wait == 0) begin
                    time_to_wait <= 120; // 60us
                    waited_time <= 0;
                end else begin
                    waited_time <= waited_time + 1;
                    if (waited_time < time_to_wait) begin
                        if (!ack) begin
                            cur_state <= redirect_to;
                            time_to_wait <= 0;
                            waited_time <= 0;
                        end
                    end else begin // time out after 60us
                        cur_state <= RAISE_ATT;
                        time_to_wait <= 0;
                        waited_time <= 0;
                    end
                end
            end
            SEND_BEGIN_TX_CMD: begin
                tx_cmd(BEGIN_TX_CMD, AWAIT_ACK, READ_PREAMBLE, 60);
            end
            READ_PREAMBLE: begin
                tx_cmd(NO_OP, AWAIT_ACK, READ_BTN_STATE_1, 24);
            end
            READ_BTN_STATE_1: begin
                tx_cmd(NO_OP, AWAIT_ACK, READ_BTN_STATE_2, 24);
            end
            READ_BTN_STATE_2: begin
                tx_cmd(NO_OP, AWAIT_ACK, READ_STICK_STATE_RX, 24);
            end
            READ_STICK_STATE_RX: begin
                tx_cmd(NO_OP, AWAIT_ACK, READ_STICK_STATE_RY, 24);
            end
            READ_STICK_STATE_RY: begin
                tx_cmd(NO_OP, AWAIT_ACK, READ_STICK_STATE_LX, 24);
            end
            READ_STICK_STATE_LX: begin
                tx_cmd(NO_OP, AWAIT_ACK, READ_STICK_STATE_LY, 24);
            end
            READ_STICK_STATE_LY: begin
                tx_cmd(NO_OP, RAISE_ATT, RAISE_ATT, 24);
            end
            RAISE_ATT: begin
                if (time_to_wait == 0) begin
                    time_to_wait <= 250;
                    waited_time <= 0;
                end else begin
                    waited_time <= waited_time + 1;
                    if (waited_time >= 14) begin
                        if (waited_time < time_to_wait) begin
                            att <= 1'b1;
                        end else begin
                            time_to_wait <= 0;
                            waited_time <= 0;
                            cur_state <= ATT_PULSE;
                            redirect_to <= LOWER_ATT;
                        end
                    end
                end
            end
            default: begin
                time_to_wait <= 0;
                waited_time <= 0;
                bit_cnt <= 8'h00;
                cur_state <= ATT_PULSE;
                redirect_to <= LOWER_ATT;
            end
        endcase
    end

    // 8 bits take 64 cycles to tx
    task tx_cmd(
        input [7:0] in_cmd,
        input [3:0] in_cur_state,
        input [3:0] in_redirect_to,
        input [31:0] initial_delay
    );  

        if (time_to_wait == 0) begin
            bit_cnt <= 8'h00;
            time_to_wait <= initial_delay + 64; // 8 bits take 64 cycles to tx
            waited_time <= 0;
        end else begin
            if(waited_time < time_to_wait) begin
                waited_time <= waited_time + 1;
                if (waited_time >= initial_delay) begin
                    if (waited_time < (initial_delay + 4 + ((bit_cnt)*8))) begin // 38us + bit_cnt*4us
                        psx_clk <= 1'b0;
                        cmd <= in_cmd[bit_cnt];
                    end else if (waited_time < (initial_delay + 7 + ((bit_cnt)*8))) begin
                        if (psx_clk == 1'b0) begin
                            if (cur_state == READ_BTN_STATE_1) begin
                                btn_state_1[4'h7 - bit_cnt] <= data;
                            end else if (cur_state == READ_BTN_STATE_2) begin
                                btn_state_2[4'h7 - bit_cnt] <= data;
                            end else if (cur_state == READ_STICK_STATE_RX) begin
                                stick_state_rx[bit_cnt] <= data;
                            end else if (cur_state == READ_STICK_STATE_RY) begin
                                stick_state_ry[bit_cnt] <= data;
                            end else if (cur_state == READ_STICK_STATE_LX) begin
                                stick_state_lx[bit_cnt] <= data;
                            end else if (cur_state == READ_STICK_STATE_LY) begin
                                stick_state_ly[bit_cnt] <= data;
                            end
                        end

                        psx_clk <= 1'b1;
                    end else begin
                        bit_cnt <= bit_cnt + 1'b1;
                    end
                end
            end else begin
                cmd <= 1'b1;
                cur_state <= in_cur_state;
                redirect_to <= in_redirect_to;
                time_to_wait <= 0;
                waited_time <= 0;
                bit_cnt <= 8'h00;
            end
        end
    endtask
endmodule