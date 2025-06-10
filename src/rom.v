module rom #(       
    parameter DATA_WIDTH = 784,
    parameter DEPTH      = 10000,
    parameter INIT_FILE  = "mem.mem" // ASCII binary dump: one 784-bit word per line
) (
    input  wire                     clk,
    input  wire                     rst,
    input  wire [$clog2(DEPTH)-1:0] addr, // address to read from
    output reg                      valid = 0,
    output reg  [DATA_WIDTH-1:0]    data_out = {DATA_WIDTH{1'b0}}
);

    // declare memory array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // initialize from hex file, each line holds one 784-bit value
    initial begin
        $readmemb(INIT_FILE, mem);
    end

    // output is registered one clock after addr is applied
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid    <= 1'b0;
            data_out <= {DATA_WIDTH{1'b0}};
        end else begin
            valid    <= 1'b1;
            data_out <= mem[addr];
        end
    end

endmodule
