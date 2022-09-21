module fake_n64_controller(
    input data_rx,
    input sample_clk,
    output data_tx
);
    // TODO: Need baton to hand back and forth between rx and tx

    fake_n64_controller_rx RX0 (
        .data_rx(data_rx),
        .sample_clk(sample_clk),
        .address(address)
    );

    fake_n64_controller_tx TX0 (
        .data_tx(data_tx)
    );
endmodule