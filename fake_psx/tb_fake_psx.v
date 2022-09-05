`timescale 10us/100ns
module tb_fake_psx();

    // Testbench variables
    reg clk = 1;
    reg data = 1;
    reg ack = 1;
    wire psx_clock;
    wire cmd; // idle HIGH
    wire att; // idle HIGH

    fake_psx PSX(
        .clk(clk),
        .data(data),
        .ack(ack),
        .psx_clk(psx_clock),
        .cmd(cmd),
        .att(att)
    );

    always begin
        #7.25; clk = ~clk; // about 7kHz
    end

    initial begin
        #40; $stop;
    end
endmodule