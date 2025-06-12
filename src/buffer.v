module buffer #(
    parameter DATA_WIDTH  = 1,
    parameter OUTPUT_SIZE = 256
) (
    input  wire                              clk,
    input  wire                              rst,
    input  wire                              enable_in, // write enable
    input  wire [$clog2(OUTPUT_SIZE)-1:0]    addr,      // where to write to
    input  wire [DATA_WIDTH-1:0]             in,        // input
    output reg  [DATA_WIDTH*OUTPUT_SIZE-1:0] out_flat   // flat output
);
    // write to selected slice
    always @(posedge clk) begin
        if (rst) begin
            out_flat <= {DATA_WIDTH*OUTPUT_SIZE{1'b0}};
        end
        else if (enable_in) begin
            out_flat[addr*DATA_WIDTH +: DATA_WIDTH] <= in;
        end
    end

endmodule
