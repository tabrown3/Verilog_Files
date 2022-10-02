`timescale 100ns/10ns // 10MHz
module tb_n64_controller();

    wire console_data;
    import_n64_data N640(.data(console_data));

    reg sample_clk;
    reg [15:0] button_state = 16'h0000;
    wire controller_data;
    wire cur_operation;
    n64_controller N64_CONT0(
        .data_rx(console_data),
        .sample_clk(sample_clk),
        .button_state(button_state),
        .data_tx(controller_data),
        .cur_operation(cur_operation)
    );

    initial begin
        sample_clk = 1'b1;
        #26700000;
        while(1) begin
            #2.5; // 250ns HIGH, 250ns LOW - 2MHz
            sample_clk = ~sample_clk;

            if (!sample_clk) begin
                button_state = $random;
            end
        end
    end
endmodule