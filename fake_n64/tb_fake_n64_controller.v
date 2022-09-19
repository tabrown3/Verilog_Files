`timescale 100ns/10ns // 10MHz, #2.5 is 4MHz
module tb_fake_n64_controller();

    wire data;
    import_saleae_n64_data FILE0(.data(data));

    reg sample_clk;
    reg reset;
    reg enable;
    wire derived_signal;
    wire derived_clk;
    async_to_sync SYNC0(
        .data(data),
        .sample_clk(sample_clk),
        .reset(reset),
        .enable(enable),
        .derived_signal(derived_signal),
        .derived_clk(derived_clk)
    );

    initial begin
        sample_clk = 1'b1;
        reset = 1'b0;
        enable = 1'b1;
        #26700000;
        while(1) begin
            #2.5; // 250ns - 4MHz
            sample_clk = ~sample_clk;
        end
    end
endmodule