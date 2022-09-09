`timescale 1us/10ns
module tb_fake_psx();

    // Testbench variables
    reg power_btn = 0;
    reg clk = 0;
    wire data;
    wire ack;
    wire psx_clk;
    wire cmd;
    wire att;

    fake_psx PSX(
        .power_btn(power_btn),
        .clk(clk),
        .data(data),
        .ack(ack),
        .psx_clk(psx_clk),
        .cmd(cmd),
        .att(att)
    );

    fake_controller CONT(
        .psx_clk(psx_clk),
        .cmd(cmd),
        .att(att),
        .clk(clk),
        .data(data),
        .ack(ack)
    );

    always begin
        #2; clk = ~clk; // 2us per toggle, 4us period (~250kHz)
    end

    initial begin
        #50; power_btn <= 1;

        #590; $stop;
    end
endmodule