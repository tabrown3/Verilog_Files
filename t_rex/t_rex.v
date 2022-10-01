`include "controller/n64/n64_controller.v"
`include "console/psx/psx_console.v"

module t_rex(
    input sample_clk,
    input psx_data,
    input psx_ack,
    input n64_rx,
    output n64_tx,
    output reg psx_clk = 1'b1,
    output reg psx_cmd = 1'b1,
    output reg psx_att = 1'b1
);

    wire [15:0] psx_btns;
    wire [15:0] n64_btns;

    // PXS controller -> N64 console mapping
    assign n64_btns = {
        ~psx_btns[14], // 0, X -> A
        ~psx_btns[13], // 1, O -> B
        0, // 2, Z
        0, // 3, S
        ~psx_btns[4], // 4, dU -> dU
        ~psx_btns[6], // 5, dD -> dD
        ~psx_btns[7], // 6, dL -> dL
        ~psx_btns[5], // 7, dR -> dR
        0, // 8, ? -> Reset
        0, // 9, ? -> ???
        0, // 10, ? -> LT
        0, // 11, ? -> RT
        0, // 12, ? -> cU
        0, // 13, ? -> cD
        0, // 14, ? -> cL
        0 // 15, ? -> cR
    };

    n64_controller CONTROLLER
    (
        .data_rx(n64_rx),
        .sample_clk(sample_clk),
        .button_state(n64_btns),
        .data_tx(n64_tx)
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

    // Modify n64 controller to forward button polls for psx console to proxy.
    // Modify psx console to forward controller button presses to n64.
    // Maybe create some signal between the two for when a poll is starting
    // and when button presses have been read and loaded.
endmodule