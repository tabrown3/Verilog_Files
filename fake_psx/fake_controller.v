module fake_controller
#(
    //        Bit0 Bit1 Bit2 Bit3 Bit4 Bit5 Bit6 Bit7
    // DATA1: SLCT           STRT UP   RGHT DOWN LEFT
    // DATA1: L2   R2    L1  R1   /\   O    X    |_|
    // source https://gamesx.com/controldata/psxcont/psxcont.htm#CIRCUIT
    parameter FAKE_DATA1 = 8'b11111110, // Pressed left on d-pad
    parameter FAKE_DATA2 = 8'b11111101 // Pressed X
    // paremeters should be removed before emulating controller
)(
    input psx_clk,
    input cmd,
    input att,
    input clk, // this is a fake input to drive the (usually analog) ack
    // NOTE: if using FPGA to emulate controller, this'll be the onboard
    // ... clock; normally this would be governed by an RC circuit
    output data,
    output ack
);

    reg [7:0] start_cmd;
    reg [7:0] request_data_cmd;
    reg out_ack = 1'b1;
    reg [1:0] ack_dur;
    reg [39:0] data_buffer = 40'hffffffffff;
    integer byte_countdown;
    reg out_data = 1'b1;

    assign ack = out_ack;
    assign data = out_data;

    // this happens before anything else
    always @(negedge att) begin
        start_cmd <= 8'h00;
        request_data_cmd <= 8'hff;
        out_ack <= 1'b1;
        ack_dur <= 1'b0;
        data_buffer <= {FAKE_DATA2, FAKE_DATA1, 8'h5a, 8'h41, 8'hff};
        byte_countdown <= 40;
    end

    always @(posedge psx_clk) begin
        // You could conceivably read the commands here, but... why?
        // There're going to be 16 bits of them.
        if (start_cmd != 8'h01) begin
            start_cmd <= {cmd, start_cmd[7:1]};
        end else if (request_data_cmd != 8'h42) begin
            request_data_cmd <= {cmd, request_data_cmd[7:1]};
        end
    end

    always @(negedge psx_clk) begin
        // if start command has been received
        if (start_cmd == 8'h01) begin
            out_data <= data_buffer[40 - byte_countdown];
        end

        byte_countdown <= byte_countdown - 1;
    end

    always @(posedge psx_clk) begin
        if (byte_countdown == 32 || byte_countdown == 24 ||
            byte_countdown == 16 || byte_countdown == 8) begin
            out_ack <= 1'b0;
        end
    end

    always @(negedge clk) begin
        if (out_ack == 1'b0) begin
            ack_dur <= ack_dur + 1'b1;
        end

        if (ack_dur == 1'b1) begin
            out_ack <= 1'b1;
            ack_dur <= 1'b0;
        end
    end
endmodule