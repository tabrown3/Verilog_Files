module fake_psx(
    input clk, // original clock from the 50MHz -> PLL -> 7kHz
    input data, // serial data from controller
    input ack, // acknowledgement from controller
    output psx_clk, // clock the psx uses to drive the controller
    output cmd, // psx uses cmd to command the controller to begin
    output att // psx should pull this low before commanding, and keep...
        // ... low for the duration of transmission
);

    reg [23:0] data_store;
    reg [15:0] start_cmds
    integer byte_countdown;
    reg wants_att = 1'b1;

    assign psx_clk = byte_countdown > 0 ? clk : 1'b1;
    assign att = wants_att;

    always @(posedge ack) begin
        byte_countdown <= 8;
    end

    always @(negedge clk) begin
        if (wants_att) begin
            wants_att <= 1'b0;
            start_cmds <= 16'h4201;
            byte_countdown <= 8;
            data_store <= 24'hxxxxxx
        end else if (byte_countdown > 0) begin
            if (start_cmds != 16'hxxxx) begin
                cmd <= start_cmds[0];
                start_cmds <= {1'bx, start_cmds[15:1]};
            end else begin
                data_store <= {data, data_store}
            end

            if (data_store[0] == 1'bx) begin
                byte_countdown <= byte_countdown - 1;
            end else begin
                wants_att <= 1'b1;
            end
        end else if (!cmd) begin
            cmd <= 1'b1;
        end
    end