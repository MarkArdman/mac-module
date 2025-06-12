
module tb_top;
  // clock & reset
  reg         clk    = 0;
  reg         rst_n  = 0;
  reg         start  = 0;

  // DUT outputs
  wire        ready;
  wire [3:0]  digit;

  reg [783:0] input_data;

  reg [783:0] test_input_data [9999:0];
  reg [3:0] expected_output [9999:0];

  // instantiate DUT
  top uut (
    .clk   (clk),
    .rst_n (rst_n),
    .start (start),
    .ready (ready),
    .digit (digit),
    .input_data(input_data)
  );

  // 100 MHz clock
  // Clock generation
  initial begin
      clk = 0;
      forever #5 clk = ~clk;  // 10ns period
  end

  integer i;
  integer failed = 0;

  initial begin
    // dump waves
    // $dumpfile("Vtb_top.vcd");
    // $dumpvars(0, tb_top);

    $readmemb("memfiles/inputs.mem", test_input_data);
    $readmemb("memfiles/expected.mem", expected_output);

    // apply reset
    rst_n = 0;
    start = 0;
    #10;
    rst_n = 1;
    #10;


    for (i = 0; i < 10000; i = i + 1) begin
      $display("Testing example: %d", i);
      
      input_data = test_input_data[i];

      #10

      // pulse start
      @(posedge clk);
      start = 1;
      @(posedge clk);
      start = 0;

      // wait for done
      wait (ready);
      @(posedge clk);

      if (digit != expected_output[i]) begin
        failed = failed + 1;
        $display("Assertion failed:");
        $display("  Example: %d", i);
        $display("  Expected: %d", expected_output[i]);
        $display("  Got: %d", digit);
      end
    end

    $display("Failed examples: %d", failed);

    #20;
    $finish;
  end

  // // log each valid pulse
  // always @(posedge valid) begin
  //   $display("++ valid pulse at %0t", $time);
  // end
endmodule
