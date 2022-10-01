`timescale 100ns/10ns // 10MHz
module tb_n64_controller();

    wire console_data;
    import_saleae_n64_data FILE0(.data(console_data));

    reg sample_clk;
    wire controller_data;
    n64_controller N64_CONT0(
        .data_rx(console_data),
        .sample_clk(sample_clk),
        .btn(2'b00),
        .data_tx(controller_data)
    );

    initial begin
        sample_clk = 1'b1;
        #26700000;
        while(1) begin
            #2.5; // 250ns HIGH, 250ns LOW - 2MHz
            sample_clk = ~sample_clk;
        end
    end
endmodule