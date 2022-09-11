module fake_controller
#(
    //        Bit0 Bit1 Bit2 Bit3 Bit4 Bit5 Bit6 Bit7
    // DATA1: SLCT           STRT UP   RGHT DOWN LEFT
    // DATA1: L2   R2    L1  R1   /\   O    X    |_|
    // source https://gamesx.com/controldata/psxcont/psxcont.htm#CIRCUIT
    parameter FAKE_DATA1 = 8'b01111111, // Pressed left on d-pad, reversed
    parameter FAKE_DATA2 = 8'b10111111 // Pressed X, reversed
    // paremeters should be removed before emulating controller
)(
    input psx_clk,
    input cmd,
    input att,
    input clk, // this is a fake input to drive the (usually analog) ack
    // NOTE: if using FPGA to emulate controller, this'll be the onboard
    // ... clock; normally this would be governed by an RC circuit
    output reg data,
    output ack
);

    reg [7:0] data0;
    reg [7:0] data1;
    reg [7:0] data2;
    reg [7:0] data3;
    reg [7:0] data4;

    always @(negedge psx_clk or negedge att)
    begin: SHIFT_REGISTER // SISO w/ preload and async reset
        if (!psx_clk) begin
            data4 <= {1'b1, data4[7:1]};
            data3 <= {data4[0], data3[7:1]};
            data2 <= {data3[0], data2[7:1]};
            data1 <= {data2[0], data1[7:1]};
            data0 <= {data1[0], data0[7:1]};
            data <= data0[0];
        end else begin // acts as the register reset
            data0 <= 8'hff;
            data1 <= 8'h41;
            data2 <= 8'h5a;
            data3 <= FAKE_DATA1;
            data4 <= FAKE_DATA2;
            data = 1'b1;
        end
    end
endmodule