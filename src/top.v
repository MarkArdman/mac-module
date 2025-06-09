`timescale 1ns / 1ps
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
    parameter N_ENTRIES = 64,
    parameter N_LEN = 8,
    parameter N_LEN_WIDTH = 3, // clog2 SQRT of N_ENTRIES, we assume square matrix with power of 2 lengths
    parameter N_ENTRIES_WIDTH = 6
)(
    input clk,
    // Reset back to the initial state
    input rst_n,
    // Enable will begin the controller FSM, which will in turn be indicated by the busy flag
    // Once busy is enabled, enable does nothing
    input enable,
    output busy,
    
    // Only need to tell the register files where to read from
    // The outputs will be fed to the MAC module
    output reg [N_ENTRIES_WIDTH-1:0] addr_a,
    output reg [N_ENTRIES_WIDTH-1:0] addr_b,
        
    // For the output we need to specify where to write, and when the entry is valid (i.e. when the mac computation is done)
    output reg [N_ENTRIES_WIDTH-1:0] addr_c,
    output reg we_c,
    
    output reg rst_n_mac,
    output reg accumulate_mac
);

reg [1:0] state_q, state_d;

reg [N_ENTRIES_WIDTH-1:0] i,j; 
reg [N_ENTRIES_WIDTH-1:0] addr_c_d;

reg rst_n_mac_q;

localparam IDLE        = 0,
           ENTER_MULTIPLY       = 1,
           MULTIPLYING = 2;

           
assign busy = state_q != IDLE;

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        state_q <= IDLE;
        i <= 0;
        j <= 0;
        addr_c <= 0;
    end else begin
        state_q <= state_d;
        i <= addr_a;
        j <= addr_b;
        addr_c <= addr_c_d;
    end
end

// (addr_a[N_LEN_WIDTH-1:0] == {N_LEN_WIDTH{1'b1}})

always @(*) begin
    // Just some sensible defaults, in the case that we don't need to do anything e.g. we are idling
    rst_n_mac = 1;
    state_d = IDLE;
    we_c = 0;
    addr_a = i;
    addr_b = j;
    addr_c_d = addr_c;
    accumulate_mac = 1;
    
    case (state_q)
        // We need this state to allow the MAC to start doing its thing
        ENTER_MULTIPLY: begin
            // MAC will now have been reset
            state_d = MULTIPLYING;
        end
        MULTIPLYING: begin
            state_d = MULTIPLYING;
            // Check i and j and do stuff
            
            // End of row/column
             if (i[N_LEN_WIDTH-1:0] == {N_LEN_WIDTH{1'b1}}) begin
                we_c = 1;
                accumulate_mac = 0;
                addr_c_d = addr_c + 1;
                // END of algorithm,go back to idling
                if (j == N_ENTRIES-1 && i == N_ENTRIES-1) begin
                    state_d = IDLE;
                end
                // Only end of this row, move onto next row and reset columns
                else if (j == N_ENTRIES-1) begin
                    addr_a = i + 1;
                    addr_b = 0;   
                end
                // Only end of this column, move on to next column and reset row
                else begin
                    addr_a = i - (N_LEN - 1);
                    addr_b = j - (N_LEN * (N_LEN - 1)) + 1; 
                end
            end
            // Not the end of either, advance both by 1
            else begin
                addr_a = i + 1;
                addr_b = j + N_LEN;
            end           
        end
        IDLE: begin
            if (enable) begin
                state_d = ENTER_MULTIPLY;
                rst_n_mac = 0;
            end
        end
    endcase
end

endmodule
