module fake_psx_two
#(
    parameter [31:0] BOOT_TIME = 16E6 // 8 seconds at 500ns per cycle
)
(
    input clk,
    input data,
    input ack,
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
    localparam [STATE_SIZE-1:0] AWAIT_ACK = 4'h4;
    localparam [STATE_SIZE-1:0] SEND_BEGIN_TX_CMD = 4'h5;
    localparam [STATE_SIZE-1:0] READ_PREAMBLE = 4'h6;
    localparam [STATE_SIZE-1:0] READ_CONT_STATE_1 = 4'h7;
    localparam [STATE_SIZE-1:0] READ_CONT_STATE_2 = 4'h8;
    localparam [STATE_SIZE-1:0] RAISE_ATT = 4'h9;
    // END STATES
    localparam [7:0] NO_OP = 8'h00;
    localparam [7:0] START_CMD = 8'h01;
    localparam [7:0] BEGIN_TX_CMD = 8'h42;

    reg [STATE_SIZE-1'b1:0] cur_state = STARTUP;
    reg [STATE_SIZE-1'b1:0] redirect_to;
    reg [31:0] time_to_wait = 0;
    reg [31:0] waited_time = 0;
    reg [7:0] bit_cnt = 8'h00;
    reg [7:0] data_byte;

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
                    time_to_wait <= 15; // 7.5us at 500ns per cycle
                    waited_time <= 0;
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
            SEND_START_CMD: begin
                tx_cmd(START_CMD, AWAIT_ACK, SEND_BEGIN_TX_CMD, 76, data_byte);
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
                        end
                    end else begin // time out after 60us
                        cur_state <= RAISE_ATT;
                        time_to_wait <= 0;
                        waited_time <= 0;
                    end
                end
            end
            SEND_BEGIN_TX_CMD: begin
                tx_cmd(BEGIN_TX_CMD, AWAIT_ACK, READ_PREAMBLE, 60, data_byte);
            end
            READ_PREAMBLE: begin
                tx_cmd(NO_OP, AWAIT_ACK, READ_CONT_STATE_1, 14, data_byte);
            end
            READ_CONT_STATE_1: begin
                tx_cmd(NO_OP, AWAIT_ACK, READ_CONT_STATE_2, 14, data_byte);
            end
            READ_CONT_STATE_2: begin
                tx_cmd(NO_OP, AWAIT_ACK, RAISE_ATT, 14, data_byte);
            end
            RAISE_ATT: begin
                if (time_to_wait == 0) begin
                    time_to_wait <= 250;
                    waited_time <= 0;
                end else if (waited_time >= 14) begin
                    waited_time <= waited_time + 1;
                    if (waited_time < 250) begin
                        att <= 1'b1;
                    end else begin
                        time_to_wait <= 0;
                        waited_time <= 0;
                        cur_state <= ATT_PULSE;
                        redirect_to <= LOWER_ATT;
                    end
                end
            end
        endcase
    end

    // 8 bits take 64 cycles to tx
    task tx_cmd;
        input [7:0] in_cmd;
        input [3:0] in_cur_state;
        input [3:0] in_redirect_to;
        input [31:0] initial_delay;
        output reg [7:0] out_data;
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
                            out_data[bit_cnt] <= data;
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