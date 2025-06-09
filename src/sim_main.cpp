#include "Vtb_tree_adder.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    
    Vtb_tree_adder* tb = new Vtb_tree_adder;
    VerilatedVcdC* tfp = new VerilatedVcdC;
    
    tb->trace(tfp, 99);
    tfp->open("Vtb_tree_adder.vcd");
    
    while (!Verilated::gotFinish()) {
        tb->eval();
        tfp->dump(Verilated::time());
        Verilated::timeInc(1);
    }
    
    tfp->close();
    delete tb;
    return 0;
}