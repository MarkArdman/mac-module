module mac_module(
    input clk, rst,
    input [783:0] inputs,
    input [783:0] weights,
    input [391:0] mask,
    output reg result,
    output reg done
);
    
    // If it's second layer, set the inputs above 255 to be of certain value
    //inputs = {your_inputs, {264{1'b0}}, {264{1'b1}}};
    //weights = {your_inputs, {264{1'b0}}, {264{1'b0}}};

    // I can easily change it later, but for now it's good enough, and let's see what playes
    // better for contrl

    // Apply mask to inputs and weights
    reg [783:0] masked_inputs;
    reg [783:0] masked_weights;

    integer k;
    always @(*) begin
        for (k = 0; k < 392; k = k + 1) begin
            if (mask[k] == 1'b0) begin
                // When mask is 0, set both bits of the pair to 0
                masked_inputs[2*k] = 1'b0;
                masked_inputs[2*k+1] = 1'b0;
                masked_weights[2*k] = 1'b0;
                masked_weights[2*k+1] = 1'b1;
            end else begin
                // When mask is 1, pass through original values
                masked_inputs[2*k] = inputs[2*k];
                masked_inputs[2*k+1] = inputs[2*k+1];
                masked_weights[2*k] = weights[2*k];
                masked_weights[2*k+1] = weights[2*k+1];
            end
        end
    end

    

    wire [1:0] activations [783:0];

    // Plain Tree Adder
    // 0: 784 inputs
    // 1: 392 FAs -> 3 out/ 1D, 392 A
    // 2: 196 FAs -> 4 out/ 2D, 196 A
    // 3: 98 FAs -> 5 out/ 3D, 98 A
    // 4: 49 FAs -> 6 out/ 4D, 49 A
    // 5: 25 FAs -> 7 out/ 5D, 25 A
    // 6: 13 FAs -> 8 out/ 6D, 13 A
    // 7: 7 FAs -> 9 out/ 7D, 7 A
    // 8: 4 FAs -> 10 out/ 8D, 4 A
    // 9: 2 FAs -> 11 out/ 9D, 2 A
    // Total: 66 D / 786 A 
    // Compound = 66 D * 786 A = 51876 AD
    // Reduction Tree / Dadda,Wallace
    // 15 steps + 1 addition, so 15 D + 11 D = 26 D
    // Uses 1380 FAs, + at worst 11 FAs for adder, 1391 A
    // Compound = 26 D * 1391 A = 36166 AD

    // Well now figured reduction trees don't handle signed numbers as well sadge
    // Some fuckery, it's fast-ish now? It's not like a fully proper textbook reduction tree
    // But if I go through the hassle of adding the half adders-etc to make it complete
    // We will gain a tiny bit and it will be a lot of fuckery.
    // And my calculations were a bit off, and it's actually quicker even so let's see how it performs actually




    // First generate outputs of all XNORs
    genvar i;
    generate
        for (i = 0; i < 784; i = i + 1) begin : xnor_array
            xnormult mult_inst (
                .a(masked_inputs[i]),
                .b(masked_weights[i]),
                .result(activations[i])
            );
        end
    endgenerate

    reg signed [13:0] sum; 
    reg signed [13:0] final_sum;

    tree_adder #(
    .NUM_INPUTS(784),
    .INPUT_BIT_WIDTH(2),  
    .OUTPUT_BIT_WIDTH(14) // Seems to complain if I make it smaller lol,so maybe it recurses a few times more than needed, but the later stages are still fast
        ) sum_tree (
    .inputs(activations),
    .sum(sum)  
    );


    // Subtract 784 from sum to get final result
    always @(*) begin
        final_sum = sum - 784;
    end

    // Now sum all of it
    // TODO: we probably will want to improve this later, but first let's see if it's terrible
    // ALso you can already use this to do functional check 

    // 11 bits to hold range [-784, +784]
    // integer j;

    // always @(*) begin
    //     final_sum = 0;
    //     for (j = 0; j < 784; j = j + 1) begin
    //         final_sum = final_sum + $signed({{9{activations[j][1]}}, activations[j]});
    //     end 
    // end

    // Give output
    always @(posedge clk) begin
        if (rst) begin
            result <= 0;
            done <= 0;
        end else begin
            result <= (final_sum >= 0) ? 1'b1 : 1'b0; 
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

    // Old version. 
    // assign result = xnor_out ? 2'b01 : 2'b11;
    // New version, everything is +1 since adder takes only positive nums
    assign result = xnor_out ? 2'b10 : 2'b00;

endmodule
