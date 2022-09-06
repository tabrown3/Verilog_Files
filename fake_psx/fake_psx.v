module fake_psx(
    input clk, // original clock from the 50MHz -> PLL -> 7kHz
    input data, // serial data from controller
    input ack, // acknowledgement from controller
    output reg psx_clk, // clock the psx uses to drive the controller
    output cmd, // psx uses cmd to command the controller to begin
    output att // psx should pull this low before commanding, and keep...
        // ... low for the duration of transmission
);

    // Internal variables
    reg out_att = 1'b1;
    reg out_cmd = 1'b1;
    integer byte_countdown = 8;
    reg [15:0] start_cmds = 16'h4201; // 0x01 - start, 0x42 - send data
    reg [4:0] start_cmd_bits_sent = 5'h00;
    reg [23:0] data_store = 24'h000000;
    reg [4:0] data_bits_received = 5'h00;

    assign att = out_att;
    assign cmd = out_cmd;

    always @(posedge clk) begin
        psx_clk <= 1'b1;
    end

    always @(posedge ack) begin
        byte_countdown <= 8;
    end

    always @(negedge clk) begin
        if (out_att) begin
            out_att <= 1'b0;
        end

        if (byte_countdown > 0) begin
            psx_clk <= 1'b0;
        end
    end

    always @(negedge out_att) begin
        byte_countdown <= 8;
        start_cmds <= 16'h4201; // 0x01 - start, 0x42 - send data
        start_cmd_bits_sent <= 5'h00;
        data_store <= 24'h000000;
        data_bits_received <= 5'h00;
    end

    always @(negedge psx_clk) begin
        if (byte_countdown > 0) begin // this line waits for ack to reset the countdown
            if (start_cmd_bits_sent < 16) begin
                out_cmd <= start_cmds[0];
                start_cmds <= {1'b1, start_cmds[15:1]};
                start_cmd_bits_sent <= start_cmd_bits_sent + 1'b1;
            end else if (data_bits_received < 24) begin
                if (data_bits_received == 0 && !out_cmd) begin
                    // when the command phase is over, set cmd HIGH...
                    // ... if not already
                    out_cmd <= 1'b1;
                end
                data_store <= {data, data_store};
                data_bits_received <= data_bits_received + 1'b1;
            end else begin
                out_att <= 1'b1;
            end

            byte_countdown <= byte_countdown - 1;
        end
    end
endmodule