`timescale 100ns/10ns // 10MHz
module tb_fake_psx_two();
    reg clk = 1'b1;
    reg data = 1'b1;
    reg ack = 1'b1;
    wire psx_clk;
    wire cmd;
    wire att;

    fake_psx_two #(.BOOT_TIME(10E4)) PSX0
    (
        .clk(clk),
        .data(data),
        .ack(ack),
        .psx_clk(psx_clk),
        .cmd(cmd),
        .att(att)
    );

    always begin
        #2.5; // 250ns HIGH, 250ns LOW - 2MHz
        clk = ~clk;
    end

    initial begin
        #(50E4);
        #900;
        ack = 1'b0;
        #4;
        ack = 1'b1;
    end

    initial begin
        #(60E4);
        $stop;
    end
endmodule