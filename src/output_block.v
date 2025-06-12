// This module takes the 256-bit flat output from the buffer register.
// It assumes that the 10 meaningful output scores/activations
// from the BNN's final layer (0-9) are located in the
// least significant 10 bits (bits 9 down to 0) of the 256-bit input.
//
// 1. Implicitly "truncates" by only looking only at the lower 10 bits of the 256-bit input.
// 2. Implements a priority encoder on these 10 bits. This means if multiple bits are '1',
//    the bit with the highest index. 
// 3. Converts the selected priority bit's index into a 4-bit binary output.

module output_block (
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [255:0] buffer_out_flat, // 256-bit output from the buffer register
    /* verilator lint_on UNUSEDSIGNAL */
    output reg  [3:0]   recognized_digit,  // 4-bit binary output (0000 for 0, 1001 for 9)
    output reg          valid_recognition  // '1' if any digit was recognized, '0' otherwise
);

    // Internal wire to hold the 10 relevant bits from the buffer output.
    // This implicitly performs the "truncation" or selection of the lower 10 bits.
    wire [9:0] digit_activation_flags;
    assign digit_activation_flags = buffer_out_flat[9:0];

    // Combinatorial logic for the priority encoder.
    always @(*) begin
        // Default values: No digit recognized, output is 0.
        recognized_digit  = 4'b0000;
        valid_recognition = 1'b0; // for varication debug

        // Priority encoding logic:
        // checks from the highest priority
        // The first '1' found determines the output, ignoring any lower-priority '1's.

        if (digit_activation_flags[0] == 1'b1) begin
            recognized_digit  = 4'b0000; // Digit 0
            valid_recognition = 1'b1;
        end else if (digit_activation_flags[1] == 1'b1) begin
            recognized_digit  = 4'b0001; // Digit 1
            valid_recognition = 1'b1;
        end else if (digit_activation_flags[2] == 1'b1) begin
            recognized_digit  = 4'b0010; // Digit 2
            valid_recognition = 1'b1;
        end else if (digit_activation_flags[3] == 1'b1) begin
            recognized_digit  = 4'b0011; // Digit 3
            valid_recognition = 1'b1;
        end else if (digit_activation_flags[4] == 1'b1) begin
            recognized_digit  = 4'b0100; // Digit 4
            valid_recognition = 1'b1;
        end else if (digit_activation_flags[5] == 1'b1) begin
            recognized_digit  = 4'b0101; // Digit 5
            valid_recognition = 1'b1;
        end else if (digit_activation_flags[6] == 1'b1) begin
            recognized_digit  = 4'b0110; // Digit 6
            valid_recognition = 1'b1;
        end else if (digit_activation_flags[7] == 1'b1) begin
            recognized_digit  = 4'b0111; // Digit 7
            valid_recognition = 1'b1;
        end else if (digit_activation_flags[8] == 1'b1) begin
            recognized_digit  = 4'b1000; // Digit 8
            valid_recognition = 1'b1;
        end else if (digit_activation_flags[9] == 1'b1) begin
            recognized_digit  = 4'b1001; // Digit 9
            valid_recognition = 1'b1;
        end

        // If none of the bits are '1', the default values (recognized_digit=0000, valid_recognition=0)
        // will remain, indicating no digit was actively recognized.
    end

endmodule
