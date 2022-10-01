`timescale 1s/1ns
module import_saleae_n64_data(
    output reg data
);
    localparam LINE_CNT = 2540;
    real elapsed_time [LINE_CNT-1:0];
    reg data_arr [LINE_CNT-1:0];
    reg cmd_arr [LINE_CNT-1:0];
    reg att_arr [LINE_CNT-1:0];
    integer in_file, i;

    initial begin
        in_file = $fopen("n64_console_data.csv", "r");

        for (i = 0; i < LINE_CNT; i = i + 1) begin
            //Time [s], Data
            $fscanf(in_file, "%f,%d", elapsed_time[i], data_arr[i]);
        end
        $fclose(in_file);
        
        #(elapsed_time[0]); data = 1;
        for (i = 1; i < LINE_CNT; i = i + 1) begin
            #(elapsed_time[i] - elapsed_time[i - 1]);
            data = data_arr[i];
        end
        $stop;
    end
endmodule