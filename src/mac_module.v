module mac_module(
    input clk, rst,
    input [783:0] inputs,
    input [783:0] weights,
    output reg result,
    output reg done
);
    
    // If it's second layer, set the inputs above 255 to be of certain value
    //inputs = {your_inputs, {264{1'b0}}, {264{1'b1}}};
    //weights = {your_inputs, {264{1'b0}}, {264{1'b0}}};

    // I can easily change it later, but for now it's good enough, and let's see what playes
    // better for contrl

    wire [1:0] activations [783:0];

    // First generate outputs of all XNORs
    genvar i;
    generate
        for (i = 0; i < 784; i = i + 1) begin : xnor_array
            xnormult mult_inst (
                .a(inputs[i]),
                .b(weights[i]),
                .result(activations[i])
            );
        end
    endgenerate

    // Now sum all of it
    // TODO: we probably will want to improve this later, but first let's see if it's terrible
    // ALso you can already use this to do functional check 

    reg signed [10:0] sum;  // 11 bits to hold range [-784, +784]
    integer j;

    always @(*) begin
        sum = 0;
        for (j = 0; j < 784; j = j + 1) begin
            sum = sum + $signed({{9{activations[j][1]}}, activations[j]});
        end 
    end

    // Give output
    always @(posedge clk) begin
        if (rst) begin
            result <= 0;
            done <= 0;
        end else begin
            result <= (sum >= 0) ? 1'b1 : 1'b0; 
            done <= 1; // do we need this tho? Chat added it but idk
        end
    end

endmodule

// Needed so my verilator doesn't cry
/* verilator lint_off DECLFILENAME */
module xnormult(
    input a,
    input b,
    output [1:0] result
);
    wire xnor_out;
    assign xnor_out = ~(a ^ b);
    assign result = xnor_out ? 2'b01 : 2'b11;
endmodule
