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
    wire [31:0] psx_sticks;
    wire [15:0] n64_btns;
    wire [7:0] n64_stick_x;
    wire [7:0] n64_stick_y;
    wire [15:0] padded_n64_stick;
    wire [7:0] single_stick_x;
    wire [7:0] single_stick_y;

    /* PSX Buttons - Digital:
        15      14      13      12      11      10      9       8
        Select                  Start   Up      Right   Down    Left
        7       6       5       4       3       2       1       0
        L2      R2      L1      R1      /\      O       X       |_|
    */

    /* PSX Buttons - Analog:
        15      14      13      12      11      10      9       8
        Select  JoyR    JoyL    Start   Up      Right   Down    Left
        7       6       5       4       3       2       1       0
        L2      R2      L1      R1      /\      O       X       |_|
    */

    /* PSX Sticks
        [31:24]
        Right Joy 0x00 = Left  0xFF = Right
        [23:16]
        Right Joy 0x00 = Up    0xFF = Down
        [15:8]
        Left Joy  0x00 = Left  0xFF = Right
        [7:0]
        Left Joy  0x00 = Up    0xFF = Down
    */

    /* N64 - Buttons
        15      14      13      12      11      10      9       8
        A       B       Z       S       dU      dD      dL      dR
        7       6       5       4       3       2       1       0
        Reset           LT      RT      cU      cD      cL      cR
    */

    /* N64 - Sticks
        [15:8]
        X-Axis -128 to 127 two's complement
        [7:0]
        Y-Axis -128 to 127 two's complement
    */

    // PXS controller -> N64 console mapping
    assign n64_btns = {
        ~psx_btns[1],   // 15, X -> A
        (~psx_btns[2] | ~psx_btns[0]),   // 14, O or |_| -> B
        ~psx_btns[6],   // 13, R2 -> Z
        ~psx_btns[12],  // 12, Start -> S
        1'b0,           // 11, ? -> dU
        1'b0,           // 10, ? -> dD
        1'b0,           // 9, ? -> dL
        1'b0,           // 8, ? -> dR
        1'b0,           // 7, ? -> Reset
        1'b0,           // 6, ? -> ???
        ~psx_btns[5],   // 5, L1 -> LT
        (~psx_btns[4] | ~psx_btns[7]),   // 4, R1 or L2 -> RT
        ~psx_btns[11],  // 3, dU -> cU
        ~psx_btns[9],   // 2, dD -> cD
        ~psx_btns[8],   // 1, dL -> cL
        ~psx_btns[10]   // 0, dR -> cR
    };

    // if L2 held down, switch to R-stick, else L-stick
    assign single_stick_x = ~psx_btns[7] ? psx_sticks[31:24] : psx_sticks[15:8];
    assign single_stick_y = ~psx_btns[7] ? psx_sticks[23:16] : psx_sticks[7:0];

    // transform to two's complement
    assign n64_stick_x = single_stick_x + 8'h80;
    // two's complement with inverted y-axis
    assign n64_stick_y = 8'h7f - single_stick_y;

    // create dead-zone where analog sticks won't cause movement
    assign padded_n64_stick = {
        single_stick_x > 8'h90 || single_stick_x < 8'h70 ? n64_stick_x : 8'h00,
        single_stick_y > 8'h90 || single_stick_y < 8'h70 ? n64_stick_y : 8'h00
    };

    n64_controller CONTROLLER
    (
        .data_rx(n64_rx),
        .sample_clk(sample_clk),
        .button_state(n64_btns),
        .stick_state(padded_n64_stick),
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
        .button_state(psx_btns),
        .stick_state(psx_sticks)
    );
endmodule