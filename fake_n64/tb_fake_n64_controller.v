`timescale 100ns/10ns // 10MHz, #5 is 2MHz
module tb_fake_n64_controller();

    wire data;
    import_saleae_n64_data FILE0(.data(data));

    reg sample_clk;
    wire derived_signal;
    wire derived_clk;
    async_to_sync SYNC0(
        .data(data),
        .sample_clk(sample_clk),
        .derived_signal(derived_signal),
        .derived_clk(derived_clk)
    );

    initial begin
        sample_clk = 1;
        #26700000;
        while(1) begin
            #5; // 500ns - 2MHz
            sample_clk = ~sample_clk;
        end
    end
endmodule