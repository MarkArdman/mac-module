module top
(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,

    input wire [783:0] input_data,

    // goes high when the entire hidden‐layer pass is complete
    output wire        ready,

    // stub for eventual classifier; drives 0 until you hook up your decoder
    output wire [3:0]  digit
);

  // Controller signals
  wire        input_select;        // 0 = use input_rom_data, 1 = use buffer_data
  wire [8:0]  weight_address;
  wire [391:0] mask;
  wire        buffer_reset;
  wire        buffer_write_enable;
  wire [7:0]  buffer_address;

  // roms
  wire [783:0] weight_rom_data;

  // datapath
  wire [783:0] mac_inputs;
  wire         mac_result;
  wire [255:0] buffer_data_flat;
  wire [15:0] output_data_flat;

  //===========================================================
  // Instantiate weight ROM
  //===========================================================
  rom #(
    .DATA_WIDTH (784),
    .DEPTH      (266),
    .INIT_FILE  ("memfiles/weights.mem")
  ) weight_rom (
    .clk      (clk),
    .rst      (1'b0),
    .addr     (weight_address),
    /* verilator lint_off PINCONNECTEMPTY */
    .valid (),
    /* verilator lint_on PINCONNECTEMPTY */
    .data_out (weight_rom_data)
  );

  //===========================================================
  // multiplexer: select between raw input or buffered activations
  //===========================================================
  // For hidden‐layer we always need 784‐bit inputs; when selecting
  // buffer_data (256 bits), we zero–pad the high bits [783:256].
  assign mac_inputs = (input_select == 1'b0)
                      ? input_data
                      : {528'b0, buffer_data_flat};

  //===========================================================
  // Instantiate MAC module
  //===========================================================
  mac_module mac (
    .inputs  (mac_inputs),
    .weights (weight_rom_data),
    .mask    (mask),
    .result  (mac_result)
  );

  //===========================================================
  // Instantiate buffer to collect MAC results
  //===========================================================
  buffer #(
    .DATA_WIDTH  (1),
    .OUTPUT_SIZE (256)
  ) buffer_register (
    .clk        (clk),
    .rst        (buffer_reset),
    .enable_in  (buffer_write_enable),
    .addr       (buffer_address),
    .in         (mac_result),
    .out_flat   (buffer_data_flat)
  );

  //===========================================================
  // Instantiate buffer to collect output results
  //===========================================================
  buffer #(
    .DATA_WIDTH  (1),
    .OUTPUT_SIZE (16)
  ) output_register (
    .clk        (clk),
    /* verilator lint_off PINCONNECTEMPTY */
    .rst        (),
    /* verilator lint_on PINCONNECTEMPTY */
    .enable_in  (!buffer_write_enable),
    .addr       (buffer_address[3:0]),
    .in         (mac_result),
    .out_flat   (output_data_flat)
  );

  //===========================================================
  // Instantiate controller FSM
  //===========================================================
  controller #(
    .HIDDEN_LAYER_FILE("memfiles/hidden_layer_width.mem"),
    .MASK_FILE        ("memfiles/mask.mem")
  ) ctrl (
    .clk                  (clk),
    .rst_n                (rst_n),
    .start                (start),
    .ready                (ready),
    .input_select         (input_select),
    .weight_address       (weight_address),
    .mask                 (mask),
    .buffer_reset         (buffer_reset),
    .buffer_address       (buffer_address),
    .buffer_write_enable  (buffer_write_enable)
  );

  //===========================================================
  // Top‐level outputs
  //===========================================================
  output_block output_blk (
    .buffer_out_flat (output_data_flat),
    .recognized_digit(digit)
  );

endmodule
