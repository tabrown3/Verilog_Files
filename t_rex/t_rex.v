module t_rex(
    input sample_clk,
    input psx_data,
    input psx_ack,
    input n64_rx,
    output n64_tx,
    output n64_cur_operation,
    output psx_clk,
    output psx_cmd,
    output psx_att
);

    wire [15:0] psx_btns;
    wire [15:0] n64_btns;

    // PXS controller -> N64 console mapping
    assign n64_btns = {
        ~psx_btns[14], // 0, X -> A
        ~psx_btns[13], // 1, O -> B
        1'b0, // 2, Z
        1'b0, // 3, S
        ~psx_btns[4], // 4, dU -> dU
        ~psx_btns[6], // 5, dD -> dD
        ~psx_btns[7], // 6, dL -> dL
        ~psx_btns[5], // 7, dR -> dR
        1'b0, // 8, ? -> Reset
        1'b0, // 9, ? -> ???
        1'b0, // 10, ? -> LT
        1'b0, // 11, ? -> RT
        1'b0, // 12, ? -> cU
        1'b0, // 13, ? -> cD
        1'b0, // 14, ? -> cL
        1'b0 // 15, ? -> cR
    };

    n64_controller CONTROLLER
    (
        .data_rx(n64_rx),
        .sample_clk(sample_clk),
        .button_state(psx_btns),
        .data_tx(n64_tx),
        .cur_operation(n64_cur_operation)
    );

    psx_console CONSOLE
    (
        .clk(sample_clk),
        .data(psx_data),
        .ack(psx_ack),
        .psx_clk(psx_clk),
        .cmd(psx_cmd),
        .att(psx_att),
        .button_state(psx_btns)
    );
endmodule