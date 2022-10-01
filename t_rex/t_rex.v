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

    n64_controller CONTROLLER
    (
        .data_rx(n64_rx),
        .sample_clk(sample_clk),
        .btn(2'b00),
        .data_tx(n64_tx)
    );

    psx_console #(.BOOT_TIME(10E4)) CONSOLE
    (
        .clk(sample_clk),
        .data(psx_data),
        .ack(psx_ack),
        .psx_clk(psx_clk),
        .cmd(psx_cmd),
        .att(psx_att)
    );

endmodule