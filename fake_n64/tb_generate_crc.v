`timescale 1us/100ns
module tb_generate_crc ();

    reg reset = 1'b0;
    reg enable = 1'b1;
    reg clk = 1'b1;
    reg data = 1'b0;
    wire [7:0] crc;

    reg [7:0] test_data [9:0];
    integer i;
    integer j;

    generate_crc CRC0(
        .reset(reset),
        .enable(enable),
        .clk(clk),
        .data(data),
        .rem(crc)
    );

    initial begin
        test_data[0] = 8'h31;
        test_data[1] = 8'h32;
        test_data[2] = 8'h33;
        test_data[3] = 8'h34;
        test_data[4] = 8'h35;
        test_data[5] = 8'h36;
        test_data[6] = 8'h37;
        test_data[7] = 8'h38;
        test_data[8] = 8'h39;
        test_data[9] = 8'h00; // data must be followed up with 8 zeroes
        #1;

        for (i = 0; i < 10; i = i + 1) begin
            for (j = 7; j >= 0; j = j - 1) begin
                data = test_data[i][j];
                clk = 1'b0;
                #1;
                clk = 1'b1;
                #1;
            end
        end

        $display("CRC: %h", crc);
    end
endmodule