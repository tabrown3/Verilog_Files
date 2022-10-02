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
        ~psx_btns[1],   // 15, X -> A
        ~psx_btns[0],   // 14, O -> B
        1'b0,           // 13, Z
        1'b0,           // 12, S
        ~psx_btns[11],  // 11, dU -> dU
        ~psx_btns[9],   // 10, dD -> dD
        ~psx_btns[8],   // 9, dL -> dL
        ~psx_btns[10],  // 8, dR -> dR
        1'b0,           // 7, ? -> Reset
        1'b0,           // 6, ? -> ???
        1'b0,           // 5, ? -> LT
        1'b0,           // 4, ? -> RT
        1'b0,           // 3, ? -> cU
        1'b0,           // 2, ? -> cD
        1'b0,           // 1, ? -> cL
        1'b0            // 0, ? -> cR
    };

    n64_controller CONTROLLER
    (
        .data_rx(n64_rx),
        .sample_clk(sample_clk),
        .button_state(n64_btns),
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