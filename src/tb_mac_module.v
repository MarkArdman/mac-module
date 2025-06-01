module tb_mac_module;
    // Signals matching your mac_module
    reg clk, rst;
    reg [783:0] inputs, weights;
    wire result;
    wire done;
    
    // Instantiate your mac_module
    mac_module uut (
        .clk(clk),
        .rst(rst),
        .inputs(inputs),
        .weights(weights),
        .result(result),
        .done(done)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period
    end
    
    initial begin
        $dumpfile("mac_module.vcd");
        $dumpvars(0, tb_mac_module);
        $display("eeee = %b", done);
        // Initialize
        rst = 1;

        inputs = 784'b0;
        weights = 784'b0;
        
        
        #20;
        rst = 0;
        
        // Test case 1: All zeros
        // inputs = {{780{1'b0}}, 4'b0000};
        // weights = {{780{1'b0}}, 4'b0001};

        inputs = {{390{1'b0}}, {390{1'b1}}, 4'b1100};
        weights = {{390{1'b0}}, {390{1'b0}}, 4'b1011};

        #30;

        $display("First neuron: result = %b", result);
        $display("Sum as signed decimal: %d", $signed(uut.sum));
        assert (result == 1'b0) else $error("Expected result = 0, but got result = %b", result);
        

        // We flip one bit, sum becomes 0 and we get 1
        inputs = {{390{1'b0}}, {390{1'b1}}, 4'b1100};
        weights = {{390{1'b0}}, {390{1'b0}}, 4'b1111};

        #30;

        $display("Second neuron: result = %b", result);
        $display("Sum as signed decimal: %d", $signed(uut.sum));
        assert (result == 1'b1) else $error("Expected result = 1, but got result = %b", result);
        
        // Now all bits are 1, so sum is very high
        inputs = {{784{1'b0}}};
        weights = {{784{1'b0}}};

        #30;

        $display("Third neuron: result = %b", result);
        $display("Sum as signed decimal: %d", $signed(uut.sum));
        assert (result == 1'b1) else $error("Expected result = 1, but got result = %b", result);

        // Now not all bits are 1, so sum is very low
        inputs = {{784{1'b1}}};
        weights = {{784{1'b0}}};

        #30;

        $display("Fourth neuron: result = %b", result);
        $display("Sum as signed decimal: %d", $signed(uut.sum));
        assert (result == 1'b0) else $error("Expected result = 0, but got result = %b", result);

        
        $finish;
    end
endmodule
