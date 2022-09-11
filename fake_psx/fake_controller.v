module fake_controller
#(
    //        Bit0 Bit1 Bit2 Bit3 Bit4 Bit5 Bit6 Bit7
    // DATA1: SLCT           STRT UP   RGHT DOWN LEFT
    // DATA1: L2   R2    L1  R1   /\   O    X    |_|
    // source https://gamesx.com/controldata/psxcont/psxcont.htm#CIRCUIT
    parameter FAKE_DATA1 = 8'b01111111, // Pressed left on d-pad, reversed
    parameter FAKE_DATA2 = 8'b11111111 // Square thru L2 left unpressed
    // paremeters should be removed before emulating controller
)(
    input psx_clk,
    input cmd,
    input att,
    input clk, // this is a fake input to drive the (usually analog) ack
    // NOTE: if using FPGA to emulate controller, this'll be the onboard
    // ... clock; normally this would be governed by an RC circuit
    output reg data,
    output reg ack
);

    reg [7:0] data0;
    reg [7:0] data1;
    reg [7:0] data2;
    reg [7:0] data3;
    reg [7:0] data4;

    reg [2:0] bit_counter;
    reg [6:0] total_bit_counter;

    always @(negedge psx_clk or negedge att)
    begin: SHIFT_REGISTER // SISO w/ preload and async reset
        if (!psx_clk) begin
            data4 <= {1'b1, data4[7:1]};
            data3 <= {data4[0], data3[7:1]};
            data2 <= {data3[0], data2[7:1]};
            data1 <= {data2[0], data1[7:1]};
            data0 <= {data1[0], data0[7:1]};
            data <= data0[0];
            bit_counter <= bit_counter - 1;
            total_bit_counter <= total_bit_counter - 1;
        end else begin // acts as the register reset
            data0 <= 8'hff;
            data1 <= 8'h41;
            data2 <= 8'h5a;
            data3 <= FAKE_DATA1;
            data4 <= FAKE_DATA2;
            data <= 1'b1;
            bit_counter <= 3'b111;
            total_bit_counter <= 7'd40;
        end
    end

    always @(*) begin
        if (total_bit_counter == 40) begin
            ack <= 1'b1;
        end else if (!att && bit_counter == 7 && total_bit_counter != 0) begin
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);
            ack <= 1'b0;
            @(negedge clk);
            ack <= 1'b1;
        end
    end
endmodule