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

// Initialized through a mem file
reg [7:0] hidden_layer_width[0:0];
reg [391:0] mask_hidden_layer[0:0];

 initial begin
    $readmemb(HIDDEN_LAYER_FILE, hidden_layer_width);
    $readmemb(MASK_FILE, mask_hidden_layer);
end

localparam OUTPUT_LAYER_WIDTH = 10;

reg [7:0] layer_countup_q, layer_countup_d;
reg [8:0] weight_address_q, weight_address_d;

// Transitions are as follows:
// IDLE -> LAYER_1 (start)
// IDLE -> IDLE    (reset)
// LAYER_1 -> HIDDEN_LAYER ()
// HIDDEN_LAYER -> FINISHED
// FINISHED -> IDLE (reset)
// FINISHED -> LAYER_1 (start)
typedef enum {
    IDLE,
    LAYER_1,
    HIDDEN_LAYER,
    FINISHED
} state_t;

state_t state_q, state_d;

// I'm not too sure about the logic that follows
// This means that the values change 1 comparison delay after the state change.
// As long as this is lower than the clk period this should be fine
// But figuring out 100 parrallel things is giving me a headache 

// The finished state indicates we are ready
assign ready = state_q == FINISHED;

// Select rom INPUT when in LAYER_1, and buffer input when in HIDDEN_LAYER
assign input_select = state_q == HIDDEN_LAYER;

// Only write to the buffer address when 
assign buffer_write_enable = state_q == LAYER_1;

// Only reset the buffer when in an IDLE state 
// In reality there is no real reason to do this with just a single hidden layer width
// But if you were switching them through a configuration, you'd have to go through a reset
assign buffer_reset = state_q == IDLE;

assign buffer_address = layer_countup_q;
assign weight_address = weight_address_q;

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        state_q <= IDLE;
        layer_countup_q <= 0;
        weight_address_q <= 0;
    end else begin
        state_q <= state_d;
        layer_countup_q <= layer_countup_d;
        weight_address_q <= weight_address_d;
    end
end

always @(*) begin
    // Just some sensible defaults, in the case that we don't need to do anything e.g. we are idling
    state_d = state_q;
    mask = 392'b0;
    layer_countup_d = layer_countup_q;
    weight_address_d = weight_address_q + 1;

    case (state_q)
        IDLE, FINISHED: begin
            if (start) begin
                state_d = LAYER_1;
                layer_countup_d = 0;
                weight_address_d = 0;
            end
        end

        // I admit this could have been factored out with a register
        // But why overcomplicate?
        LAYER_1: begin
            if (layer_countup_q == hidden_layer_width[0]) begin
                state_d = HIDDEN_LAYER;
                layer_countup_d = 0;
            end else begin
                layer_countup_d = layer_countup_q + 1;
            end
        end
        
        HIDDEN_LAYER: begin
            if (layer_countup_q == OUTPUT_LAYER_WIDTH) begin
                state_d = FINISHED;
                layer_countup_d = 0;
            end else begin
                layer_countup_d = layer_countup_q + 1;
            end
            mask = mask_hidden_layer[0];
        end
    endcase
end

endmodule
