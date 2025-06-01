#include "Vtb_mac_module.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    
    Vtb_mac_module* tb = new Vtb_mac_module;
    VerilatedVcdC* tfp = new VerilatedVcdC;
    
    tb->trace(tfp, 99);
    tfp->open("mac_module.vcd");
    
    while (!Verilated::gotFinish()) {
        tb->eval();
        tfp->dump(Verilated::time());
        Verilated::timeInc(1);
    }
    
    tfp->close();
    delete tb;
    return 0;
}
