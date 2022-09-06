`timescale 10us/100ns
module tb_fake_psx();

    // Testbench variables
    // All idle HIGH
    reg clk = 1;
    wire data;
    wire ack;
    wire psx_clk;
    wire cmd;
    wire att;

    fake_psx PSX(
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
        #7.25; clk = ~clk; // about 7kHz
    end

    initial begin
        #1000; $stop;
    end
endmodule