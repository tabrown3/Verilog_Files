`include "../common/n_bit_counter.v"
module async_to_sync(
    input data,
    input sample_clk,
    input reset,
    input enable,
    output reg derived_signal = 1'b1,
    output reg derived_clk = 1'b1
);
    localparam STATE_SIZE = 4; // bits
    // STATES
    localparam [STATE_SIZE-1:0] AWAITING_FIRST_BIT = {STATE_SIZE{1'b0}};
    localparam [STATE_SIZE-1:0] READING_BIT_LOW = {{STATE_SIZE - 1{1'b0}}, 1'b1};
    localparam [STATE_SIZE-1:0] READING_BIT_HIGH = {{STATE_SIZE - 2{1'b0}}, 2'b10};
    // END STATES

    // CURRENT STATE
    reg [STATE_SIZE-1:0] cur_state = AWAITING_FIRST_BIT;
    reg low_cnt_clk = 1'b1;
    reg high_cnt_clk = 1'b1;
    wire [5:0] low_cnt;
    wire [5:0] high_cnt;
    reg reset_low_cnt = 1'b0;
    reg reset_high_cnt = 1'b0;
    reg [5:0] low_cnt_latch = 6'h00;

    n_bit_counter LOW_CNT0(.clk(low_cnt_clk), .reset(reset_low_cnt), .count(low_cnt));
    n_bit_counter HIGH_CNT0(.clk(high_cnt_clk), .reset(reset_high_cnt), .count(high_cnt));

    always @(edge sample_clk or posedge reset) begin
        if (reset) begin
            low_cnt_clk <= 1'b1;
            high_cnt_clk <= 1'b1;
            reset_low_cnt <= 1'b1;
            reset_high_cnt <= 1'b1;
            low_cnt_latch <= 6'h00;
            cur_state <= AWAITING_FIRST_BIT;
        end else if (enable) begin
            case (cur_state)
                AWAITING_FIRST_BIT: begin
                    if (!sample_clk && !data) begin
                        cur_state <= READING_BIT_LOW;
                        low_cnt_clk <= sample_clk;
                        reset_low_cnt <= 1'b0;
                        reset_high_cnt <= 1'b0;
                    end
                end
                READING_BIT_LOW: begin
                    if (!sample_clk && data) begin
                        reset_high_cnt <= 1'b0;
                        high_cnt_clk <= sample_clk;
                        cur_state <= READING_BIT_HIGH;

                        low_cnt_latch <= low_cnt;
                        reset_low_cnt <= 1'b1;
                    end else begin
                        low_cnt_clk <= sample_clk;
                        if (!derived_clk) begin
                            derived_clk <= 1'b1;
                        end
                    end
                end
                READING_BIT_HIGH: begin
                    if (!sample_clk && !data) begin
                        reset_low_cnt <= 1'b0;
                        low_cnt_clk <= sample_clk;
                        cur_state <= READING_BIT_LOW;

                        derived_clk <= 1'b0;
                        reset_high_cnt <= 1'b1;
                        if (low_cnt_latch > high_cnt) begin
                            derived_signal <= 1'b0;
                        end else begin
                            derived_signal <= 1'b1;
                        end
                    end else begin
                        high_cnt_clk <= sample_clk;
                    end
                end
            endcase
        end
    end
endmodule