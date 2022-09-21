module fake_n64_controller(
    input data_rx,
    input sample_clk,
    output data_tx
);
    localparam RX = 1'b0;
    localparam TX = 1'b1;

    reg cur_operation = RX;
    wire [7:0] cmd;
    wire tx_handoff;
    wire rx_handoff;

    fake_n64_controller_rx RX0 (
        .cur_operation(cur_operation),
        .data_rx(data_rx),
        .sample_clk(sample_clk),
        .tx_handoff(tx_handoff),
        .cmd(cmd),
        .address(address)
    );

    fake_n64_controller_tx TX0 (
        .sample_clk(sample_clk),
        .cur_operation(cur_operation),
        .cmd(cmd),
        .rx_handoff(rx_handoff),
        .data_tx(data_tx)
    );

    always @(posedge tx_handoff or posedge rx_handoff) begin
        if (tx_handoff) begin
            cur_operation <= TX;
        end else begin
            cur_operation <= RX;
        end
    end
endmodule