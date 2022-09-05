module fake_psx(
    input clk, // original clock from the 50MHz -> PLL -> 7kHz
    input data, // serial data from controller
    input ack, // acknowledgement from controller
    output psx_clk, // clock the psx uses to drive the controller
    output reg cmd, // psx uses cmd to command the controller to begin
    output att // psx should pull this low before commanding, and keep...
        // ... low for the duration of transmission
);

    // Internal variables
    reg wants_att = 1'b1;
    integer byte_countdown;
    reg [15:0] start_cmds;
    reg [4:0] start_cmd_bits_sent;
    reg [23:0] data_store;
    reg [4:0] data_bits_received;

    assign psx_clk = byte_countdown > 0 ? clk : 1'b1;
    assign att = wants_att;

    always @(posedge ack) begin // resets byte countdown on ack
        byte_countdown <= 8;
    end

    always @(negedge clk) begin
        if (wants_att) begin
            wants_att <= 1'b0;
            byte_countdown <= 8;
            start_cmds <= 16'h4201; // 0x01 - start, 0x42 - send data
            start_cmd_bits_sent <= 5'h00;
            data_store <= 24'h000000;
            data_bits_received <= 5'h00;
        end else if (byte_countdown > 0) begin // this line waits for ack to reset the countdown
            if (start_cmd_bits_sent < 16) begin
                cmd <= start_cmds[0];
                start_cmds <= {1'b1, start_cmds[15:1]};
                start_cmd_bits_sent <= start_cmd_bits_sent + 1'b1;
            end else if (data_bits_received < 24) begin
                if (data_bits_received == 0 && !cmd) begin
                    // when the command phase is over, set cmd HIGH...
                    // ... if not already
                    cmd <= 1'b1;
                end
                data_store <= {data, data_store};
                byte_countdown <= byte_countdown - 1;
                data_bits_received <= data_bits_received + 1'b1;
            end else begin
                wants_att <= 1'b1;
            end
        end
    end
endmodule