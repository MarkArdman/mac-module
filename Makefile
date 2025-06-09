VERILATOR = verilator
MODULE = tb_mac_module
SOURCES = src/mac_module.v src/tb_mac_module.v src/tree_adder.v src/tb_tree_adder.v
CPP_SRC = sim/sim_main.cpp

all: run

verilate:
	$(VERILATOR) -Wall --cc --exe --build --trace --timing -j $(shell nproc) $(SOURCES) $(CPP_SRC) --top-module $(MODULE)

run: verilate
	./obj_dir/V$(MODULE)

waves:
	gtkwave adder.vcd

clean:
	rm -rf obj_dir *.vcd

.PHONY: all verilate run waves clean
