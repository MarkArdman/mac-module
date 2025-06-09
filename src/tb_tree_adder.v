module tb_tree_adder;

// Parameters for testing
parameter INPUT_COUNT = 6;
parameter INPUT_WIDTH = 2;
parameter OUTPUT_WIDTH = 5;

// Testbench signals
reg unsigned [INPUT_WIDTH-1:0] in [0:INPUT_COUNT-1];  // Array of INPUT_WIDTH-bit registers
wire [OUTPUT_WIDTH-1:0] out;                 // Single OUTPUT_WIDTH-bit wire

reg signed [OUTPUT_WIDTH-1:0] actual_out;

// Variables for test loop


// Instantiate the tree_adder module
tree_adder #(
    .NUM_INPUTS(INPUT_COUNT),
    .INPUT_BIT_WIDTH(INPUT_WIDTH),
    .OUTPUT_BIT_WIDTH(OUTPUT_WIDTH)
) uut (
    .inputs(in),
    .sum(out)
);

initial begin
    $dumpfile("tree_adder_tb.vcd");
    $dumpvars(0, tb_tree_adder);
    
    $display("Starting Tree Adder Testbench");
    $display("INPUT_COUNT = %0d, INPUT_WIDTH = %0d, OUTPUT_WIDTH = %0d", 
             INPUT_COUNT, INPUT_WIDTH, OUTPUT_WIDTH);
    $display("Time\t\tInputs\t\tOutput\t\tExpected");
    in[5] = 2'b11;
    in[4] = 2'b00;
    in[3] = 2'b01;
    in[2] = 2'b01;
    in[1] = 2'b01;
    in[0] = 2'b01;

    #10; // Wait for propagation delay

    actual_out = out - 6;
$display("%0t\t\t%b,%b,%b\t\t%b\t\t%d", $time, in[2], in[1], in[0], out, actual_out);    

    $display("\nTest completed");
    $finish;
end

endmodule
