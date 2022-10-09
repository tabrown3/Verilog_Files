`timescale 100ns/10ns // 10MHz
module tb_psx_console();
    reg clk = 1'b1;
    reg data = 1'b1;
    reg ack = 1'b1;
    wire psx_clk;
    wire cmd;
    wire att;
    wire [15:0] button_state;

    psx_console #(.BOOT_TIME(10E4)) PSX0
    (
        .clk(clk),
        .data(data),
        .ack(ack),
        .psx_clk(psx_clk),
        .cmd(cmd),
        .att(att),
        .button_state(button_state)
    );

    always begin
        #2.5; // 250ns HIGH, 250ns LOW - 2MHz
        clk = ~clk;

        if (!clk) begin
            data = $random;
        end
    end

    initial begin
        #(50E4+(32E3*5));
        #900;
        ack = 1'b0;
        #6;
        ack = 1'b1;

        #700;
        ack = 1'b0;
        #6;
        ack = 1'b1;

        #480;
        ack = 1'b0;
        #6;
        ack = 1'b1;

        #480;
        ack = 1'b0;
        #6;
        ack = 1'b1;

        #480;
        ack = 1'b0;
        #6;
        ack = 1'b1;

        #480;
        ack = 1'b0;
        #6;
        ack = 1'b1;

        #480;
        ack = 1'b0;
        #6;
        ack = 1'b1;

        #480;
        ack = 1'b0;
        #6;
        ack = 1'b1;
    end

    initial begin
        #(15E5);
        $stop;
    end
endmodule