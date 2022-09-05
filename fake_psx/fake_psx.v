module fake_psx(
    input clk, // original clock from the 50MHz -> PLL -> 7kHz
    input data, // serial data from controller
    input ack, // acknowledgement from controller
    output psx_clk, // clock the psx uses to drive the controller
    output cmd, // psx uses cmd to command the controller to begin
    output att // psx should pull this low before commanding, and keep...
        // ... low for the duration of transmission
);

