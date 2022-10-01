module n64_controller(
    input data_rx,
    input sample_clk,
    input [15:0] button_state,
    output data_tx,
    output cur_operation
);
    localparam RX = 1'b0;
    localparam TX = 1'b1;

    wire [7:0] cmd;
    wire [15:0] address;
    wire [7:0] crc;
    wire tx_handoff;
    wire rx_handoff;

    assign cur_operation = tx_handoff == rx_handoff ? RX : TX;

    n64_controller_rx RX0 (
        .cur_operation(cur_operation),
        .data_rx(data_rx),
        .sample_clk(sample_clk),
        .tx_handoff(tx_handoff),
        .cmd(cmd),
        .address(address),
        .crc(crc)
    );

    n64_controller_tx TX0 (
        .sample_clk(sample_clk),
        .cur_operation(cur_operation),
        .cmd(cmd),
        .crc(crc),
        .button_state(button_state),
        .rx_handoff(rx_handoff),
        .data_tx(data_tx)
    );
endmodule