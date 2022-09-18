`timescale 1us/10ns
module tb_fake_controller();
    wire psx_clk, cmd, att;
    wire data, ack;
    reg clk = 0;
    reg [1:0] d_btn = 2'b00;

    import_saleae_data PSX0(
        .psx_clk(psx_clk),
        .cmd(cmd),
        .att(att)
    );

    fake_controller CONT(
        .psx_clk(psx_clk),
        .att(att),
        .clk(clk),
        .d_btn(d_btn),
        .data(data),
        .ack(ack)
    );

    initial begin
        #11000000;
        while(1) begin
            #2; clk = ~clk; // 2us per toggle, 4us period (~250kHz)
        end
    end
endmodule