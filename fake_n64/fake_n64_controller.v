module fake_n64_controller(
    input data,
    input sample_clk,
    output derived_signal,
    output derived_clk
);

    reg reset = 1'b0;
    reg enable = 1'b1;
    async_to_sync SYNC0(
        .data(data),
        .sample_clk(sample_clk),
        .reset(reset),
        .enable(enable),
        .derived_signal(derived_signal),
        .derived_clk(derived_clk)
    );
endmodule