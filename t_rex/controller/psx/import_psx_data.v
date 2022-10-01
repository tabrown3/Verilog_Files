`timescale 1s/1ns
module import_psx_data(
    output reg psx_clk,
    output reg cmd,
    output reg att
);
    localparam LINE_CNT = 352;
    real elapsed_time [LINE_CNT-1:0];
    reg psx_clk_arr [LINE_CNT-1:0];
    reg cmd_arr [LINE_CNT-1:0];
    reg att_arr [LINE_CNT-1:0];
    integer in_file, i;

    initial begin
        in_file = $fopen("three_polls_from_start.csv", "r");

        for (i = 0; i < LINE_CNT; i = i + 1) begin
            //Time [s],PSX Clk,Cmd,Att
            $fscanf(in_file, "%f,%d,%d,%d", elapsed_time[i], psx_clk_arr[i], cmd_arr[i], att_arr[i]);
        end
        $fclose(in_file);
        
        // $display("%f, %d, %d, %d", elapsed_time[0], psx_clk_arr[0], cmd_arr[0], att_arr[0]);
        #(elapsed_time[0]); psx_clk = 1; cmd = 1; att = 1;
        for (i = 1; i < LINE_CNT; i = i + 1) begin
            // $display("%f, %d, %d, %d", elapsed_time[i] - elapsed_time[i - 1], psx_clk_arr[i], cmd_arr[i], att_arr[i]);
            #(elapsed_time[i] - elapsed_time[i - 1]);
            psx_clk = psx_clk_arr[i]; cmd = cmd_arr[i]; att = att_arr[i];
        end

        $stop;
    end
endmodule