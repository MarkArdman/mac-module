module top
#(
    parameter HIDDEN_LAYER_SIZE = 64
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,

    // goes high when the entire hidden‐layer pass is complete
    output wire        ready,

    // pulses whenever mac_module produces a new 1‐bit result
    output wire        valid,

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
  wire [783:0] input_rom_data;

  // datapath
  wire [783:0] mac_inputs;
  wire         mac_result;
  wire         mac_done;
  wire [255:0] buffer_data_flat;

  //===========================================================
  // Instantiate weight ROM
  //===========================================================
  rom #(
    .DATA_WIDTH (784),
    .DEPTH      (266),
    .INIT_FILE  ("weights.mem")
  ) weight_rom (
    .clk      (clk),
    .rst      (1'b0),
    .addr     (weight_address),
    .valid    (),
    .data_out (weight_rom_data)
  );

  //===========================================================
  // Instantiate input ROM (only one address: 0)
  //===========================================================
  rom #(
    .DATA_WIDTH (784),
    .DEPTH      (1),
    .INIT_FILE  ("input.mem")
  ) input_rom (
    .clk      (clk),
    .rst      (1'b0),
    .addr     (9'd0),
    .valid    (),
    .data_out (input_rom_data)
  );

  //===========================================================
  // multiplexer: select between raw input or buffered activations
  //===========================================================
  // For hidden‐layer we always need 784‐bit inputs; when selecting
  // buffer_data (256 bits), we zero–pad the high bits [783:256].
  assign mac_inputs = (input_select == 1'b0)
                      ? input_rom_data
                      : {528'b0, buffer_data_flat};

  //===========================================================
  // Instantiate MAC module
  //===========================================================
  mac_module mac (
    .clk     (clk),
    .rst     (1'b0),
    .inputs  (mac_inputs),
    .weights (weight_rom_data),
    .mask    (mask),
    .result  (mac_result),
    .done    (mac_done)
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
  // Instantiate controller FSM
  //===========================================================
  controller #(
    .HIDDEN_LAYER_FILE("hidden_layer_width.mem"),
    .MASK_FILE        ("mask.mem")
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
    .buffer_out_flat (buffer_data_flat),
    .recognized_digit(digit),
    .valid_recognition()
  );

endmodule
