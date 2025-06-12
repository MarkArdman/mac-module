
module tb_top;
  // clock & reset
  reg         clk    = 0;
  reg         rst_n  = 0;
  reg         start  = 0;

  // DUT outputs
  wire        ready;
  wire        valid;
  wire [3:0]  digit;

  // instantiate DUT
  top #(
    .HIDDEN_LAYER_SIZE(64)
  ) uut (
    .clk   (clk),
    .rst_n (rst_n),
    .start (start),
    .ready (ready),
    .valid (valid),
    .digit (digit)
  );

  // 100 MHz clock
  always #5 clk = ~clk;

  initial begin
    // dump waves
    $dumpfile("tb_top.vcd");
    $dumpvars(0, tb_top);

    // apply reset
    rst_n = 0;
    start = 0;
    #20;
    rst_n = 1;
    #10;

    // pulse start
    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;

    // wait for done
    wait (ready);
    @(posedge clk);
    $display("** ready asserted at %0t", $time);
    $display("** output digit = %0d", digit);

    #20;
    $finish;
  end

  // log each valid pulse
  always @(posedge valid) begin
    $display("++ valid pulse at %0t", $time);
  end
endmodule
