`timescale 10us/100ns
module tb_fake_psx();

    reg clk = 1;

    always begin
        #7.25; clk = ~clk; // about 7kHz
    end

    initial begin
        #40; $stop;
    end
endmodule