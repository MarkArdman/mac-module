//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/12/2025 04:53:57 PM
// Design Name: 
// Module Name: controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module top
#(
    parameter HIDDEN_LAYER_SIZE = 64,
)(
    input clk,
    input rst_n,
    input start,
   
    output valid,
    output ready,
    output [3:0] digit
);

wire [8:0] weight_rom_address;
wire [783:0] weight_rom_data;
wire [783:0] input_rom_data;

wire buffer_reset;
wire buffer_write_enable;
wire [7:0] buffer_address;
wire [255:0] buffer_data;

wire [0:0] mac_data;
wire [783:0] mac_inputs;
wire [391:0] mask;

rom #(       
    parameter DATA_WIDTH = 784,
    parameter DEPTH      = 266, // This needs to be a verilog setting or something we can edit during configuration
    parameter INIT_FILE  = "memfiles/weights.mem" // ASCII binary dump: one 784-bit word per line
) weight_rom (
    .clk(clk),
    .rst(0),
    .addr(weight_rom_address), // address to read from
    .valid(),
    .data_out(weight_rom_data)
);

rom #(       
    parameter DATA_WIDTH = 784,
    parameter DEPTH      = 1,
    parameter INIT_FILE  = "memfiles/input.mem" // ASCII binary dump: one 784-bit word per line
) weight_rom (
    .clk(clk),
    .rst(0),
    .addr(0), // address to read from
    .valid(),
    .data_out(input_rom_data)
);

buffer #(
    parameter DATA_WIDTH  = 1,
    parameter OUTPUT_SIZE = 256
) buffer_register (
    .clk(clk),
    .rst(buffer_reset),
    .enable_in(buffer_write_enable), // write enable
    .addr(buffer_address),      // where to write to
    .in(mac_output),        // input
    .out_flat(buffer_data)   // flat output
);

mac_module mac (
    .clk
    .rst(0),
    .inputs(mac_inputs),
    .weights(weight_rom_data),
    .mask(mask),
    .result(mac_data),
    .done()
);

module controller
#(       
    parameter HIDDEN_LAYER_FILE = "memfiles/hidden_layer_width.mem",
    parameter MASK_FILE = "memfiles/mask.mem"
)
(
    input clk,

    // Reset back to the initial state
    input rst_n,

    // Start will begin the computation, which ends when the ready flag is raised
    input start,
    
    // Raised when the computation has finished
    // This also means the FSM is in the FINISHED state, and will remain there
    // until reset or started again
    output ready,
    
    // Whether to read from input ROM or the buffer register
    output input_select,

    // Whether to output layer 1 or hidden layer weights
    output [8:0] weight_address,

    // Mask for the output of the MAC module
    output reg [391:0] mask,

    // Reset for buffer register
    output buffer_reset,

    // Write address for the buffer
    output [7:0] buffer_address,

    // Write output of MAC to buffer
    output buffer_write_enable
);



endmodule
