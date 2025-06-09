module tree_adder #(
    parameter NUM_INPUTS = 784,
    parameter INPUT_BIT_WIDTH = 2,
    parameter OUTPUT_BIT_WIDTH = 10  // Needs to be log2(NUM_INPUTS) + INPUT_BIT_WIDTH
)(
    input [INPUT_BIT_WIDTH-1:0] inputs [NUM_INPUTS-1:0],
    output [OUTPUT_BIT_WIDTH-1:0] sum
);

generate
    // Base cases
    if (NUM_INPUTS == 1) begin: base_case_1
        assign sum = inputs[0];
    end
    else if (NUM_INPUTS == 2) begin: base_case_2
        assign sum = inputs[0] + inputs[1];
    end
    else if (NUM_INPUTS == 3) begin: base_case_3
        assign sum = inputs[0] + inputs[1] + inputs[2];
    end
    else begin: recursive_case
        // Calculate how many outputs we'll have after compression
        localparam GROUPS_OF_3 = NUM_INPUTS / 3;
        localparam REMAINDER = NUM_INPUTS % 3;
        localparam NEXT_LEVEL_SIZE = GROUPS_OF_3 + (REMAINDER > 0 ? 1 : 0);
        
        // Intermediate signals for next level
        wire [INPUT_BIT_WIDTH+1:0] next_level [NEXT_LEVEL_SIZE-1:0];
        
        genvar i;
        
        // Process groups of 3 inputs
        for (i = 0; i < GROUPS_OF_3; i = i + 1) begin: group_3_adder
            assign next_level[i] = {2'b0, inputs[i*3]} + {2'b0, inputs[i*3+1]} + {2'b0, inputs[i*3+2]};
        end
        
        // Handle remaining inputs
        if (REMAINDER == 1) begin: handle_remainder_1
            assign next_level[GROUPS_OF_3] = {2'b0, inputs[GROUPS_OF_3*3]};
        end
        else if (REMAINDER == 2) begin: handle_remainder_2
            assign next_level[GROUPS_OF_3] = {2'b0, inputs[GROUPS_OF_3*3]} + {2'b0, inputs[GROUPS_OF_3*3+1]};
        end
        
        // Recursive call
        tree_adder #(
            .NUM_INPUTS(NEXT_LEVEL_SIZE),
            .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH + 2),
            .OUTPUT_BIT_WIDTH(OUTPUT_BIT_WIDTH)
        ) recursive_adder (
            .inputs(next_level),
            .sum(sum)
        );
    end
endgenerate

endmodule
