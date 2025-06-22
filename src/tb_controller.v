module tb_controller;

    // Inputs
    reg clk;
    reg rst_n;
    reg start;

    // Outputs
    wire ready;
    wire input_select;
    wire [8:0] weight_address;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [391:0] mask;
    wire buffer_reset;
    wire [7:0] buffer_address;
    wire buffer_write_enable;

    controller uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .ready(ready),
        .input_select(input_select),
        .weight_address(weight_address),
        .mask(mask),
        .buffer_reset(buffer_reset),
        .buffer_address(buffer_address),
        .buffer_write_enable(buffer_write_enable)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period
    end

    initial begin
        // Initialize Inputs
        clk = 0;
        rst_n = 0;
        start = 0;

        // Hold reset for a few cycles
        #20;
        rst_n = 1;

        // Start computation
        #10;
        start = 1;
        #10;
        start = 0;

        // Wait until ready is high (FSM reached FINISHED)
        wait(ready);

        #20;
        $display("Test completed.");
        $finish;
    end

    // Monitor outputs for debug
    always @(posedge clk) begin
        $display("Time: %0t | State Output: ready=%b, input_select=%b, weight_address=%d, buffer_write_enable=%b, buffer_reset=%b, buffer_address=%d", 
                 $time, ready, input_select, weight_address, buffer_write_enable, buffer_reset, buffer_address);
    end

endmodule
