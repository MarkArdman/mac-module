VERILATOR = verilator

include config.mk

all: run

verilate:
	$(VERILATOR) -Wall --Wno-fatal --cc --exe --build --trace --timing -j $(shell nproc) $(SOURCES) $(CPP_SRC) --top-module $(MODULE)

run: verilate
	./obj_dir/V$(MODULE)

waves:
	gtkwave V$(MODULE).vcd

clean:
	rm -rf obj_dir *.vcd

.PHONY: all verilate run waves clean
