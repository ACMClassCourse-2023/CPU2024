PWD := $(CURDIR)

SRC_DIR := $(PWD)/src
TESTSPACE_DIR := $(PWD)/testspace
TESTCASE_DIR := $(PWD)/testcase

SIM_TESTCASE_DIR := $(TESTCASE_DIR)/sim
FPGA_TESTCASE_DIR := $(TESTCASE_DIR)/fpga

SIM_DIR := $(PWD)/sim

V_SOURCES := $(shell find $(SRC_DIR) -name '*.v')

ONLINE_JUDGE ?= false

IV_FLAGS := -I$(SRC_DIR) -Wall -Wno-timescale

ifeq ($(ONLINE_JUDGE), true)
IV_FLAGS += -D ONLINE_JUDGE
all: build_sim
	@cp $(TESTSPACE_DIR)/test $(PWD)/code
else
all: testcases build_sim
endif

testcases:
	@make -C $(TESTCASE_DIR)

_no_testcase_name_check:
ifndef name
	$(error name is not set. Usage: make run_sim name=your_testcase_name)
endif

$(TESTSPACE_DIR):
	@mkdir -p $(TESTSPACE_DIR)

build_sim: $(SIM_DIR)/testbench.v $(V_SOURCES) $(TESTSPACE_DIR)
	@iverilog $(IV_FLAGS) -o $(TESTSPACE_DIR)/test $(SIM_DIR)/testbench.v $(V_SOURCES)

build_sim_test: testcases _no_testcase_name_check
	@cp $(SIM_TESTCASE_DIR)/*$(name)*.c $(TESTSPACE_DIR)/test.c
	@cp $(SIM_TESTCASE_DIR)/*$(name)*.data $(TESTSPACE_DIR)/test.data
	@cp $(SIM_TESTCASE_DIR)/*$(name)*.dump $(TESTSPACE_DIR)/test.dump
	@cp $(SIM_TESTCASE_DIR)/*$(name)*.ans $(TESTSPACE_DIR)/test.ans
	@find $(SIM_TESTCASE_DIR) -name '*$(name)*.in' -exec cp {} $(TESTSPACE_DIR)/test.in \;


build_fpga_test: testcases _no_testcase_name_check $(TESTSPACE_DIR)
	@cp $(FPGA_TESTCASE_DIR)/*$(name)*.c $(TESTSPACE_DIR)/test.c
	@cp $(FPGA_TESTCASE_DIR)/*$(name)*.elf $(TESTSPACE_DIR)/test.elf
	@cp $(FPGA_TESTCASE_DIR)/*$(name)*.dump $(TESTSPACE_DIR)/test.dump
# sometimes the input and output file not exist
	@rm -f $(TESTSPACE_DIR)/test.in $(TESTSPACE_DIR)/test.ans
	@find $(FPGA_TESTCASE_DIR) -name '*$(name)*.in' -exec cp {} $(TESTSPACE_DIR)/test.in \;
	@find $(FPGA_TESTCASE_DIR) -name '*$(name)*.ans' -exec cp {} $(TESTSPACE_DIR)/test.ans \;

run_sim: build_sim build_sim_test
	cd $(TESTSPACE_DIR) && ./test
# add your own test script here
# Example:
#	diff ./test/test.ans ./test/test.out


fpga_device := /dev/ttyUSB1
fpga_run_mode := -T # or -I

# Please manually load .bit file to FPGA
run_fpga: build_fpga_test
	cd $(TESTSPACE_DIR) && if [ -f test.in ]; then $(PWD)/fpga/fpga test.elf test.in $(fpga_device) $(fpga_run_mode); else $(PWD)/fpga/fpga test.elf $(fpga_device) $(fpga_run_mode); fi

clean:
	rm -f $(TESTSPACE_DIR)/test*

.PHONY: all build_sim build_sim_test run_sim clean
