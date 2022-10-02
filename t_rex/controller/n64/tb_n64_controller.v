`timescale 100ns/10ns // 10MHz
module tb_n64_controller();

    wire console_data;
    import_n64_data N640(.data(console_data));

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

    reg sample_clk;
    reg [15:0] button_state = 16'h0000;
    wire controller_data;
    wire cur_operation;
    n64_controller N64_CONT0(
        .data_rx(console_data),
        .sample_clk(sample_clk),
        .button_state(n64_btns),
        .data_tx(controller_data),
        .cur_operation(cur_operation)
    );

    assign psx_btns = button_state;

    always @(posedge cur_operation) begin
        button_state <= $random;
    end

    initial begin
        sample_clk = 1'b1;
        #26700000;
        while(1) begin
            #2.5; // 250ns HIGH, 250ns LOW - 2MHz
            sample_clk = ~sample_clk;
        end
    end
endmodule