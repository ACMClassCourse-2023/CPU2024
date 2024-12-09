PWD := $(CURDIR)

# riscv 工具链前缀
RISCV_TOOLCHAIN ?= riscv64-elf-

TESTCASE_SRCS := $(shell find $(PWD) -name '*.c')

DATAFILES := $(TESTCASE_SRCS:.c=.data)
DUMPFILES := $(TESTCASE_SRCS:.c=.dump)

.SECONDARY: $(TESTCASE_SRCS:.c=.elf)

# compile tools
AS := $(RISCV_TOOLCHAIN)as
CC := $(RISCV_TOOLCHAIN)gcc
LD := $(RISCV_TOOLCHAIN)ld
OBJCOPY := $(RISCV_TOOLCHAIN)objcopy
OBJDUMP := $(RISCV_TOOLCHAIN)objdump

# compile options
# Link library least support: [ rv32i rv32iac rv32im rv32imac rv32imafc rv64imac rv64imafdc ] if use the given dockerfile(archlinux with riscv64-elf-newlib)
# other option such as _zicsr might be available as well
MARCH_STRING := rv32ic
ABI_STRING := ilp32

AS_FLAGS := -march=$(MARCH_STRING)
C_FLAGS := -I $(PWD) -O2 -march=$(MARCH_STRING) -mabi=$(ABI_STRING) -g -std=c17

all: $(DATAFILES) $(DUMPFILES)

# 生成.dump文件
%.dump: %.elf
	@$(OBJDUMP) -D $< > $@

# 生成.data文件，根据文件名包含fpga决定输出格式
%.data: %.elf
	@if echo "$@" | grep -q "fpga"; then \
		$(OBJCOPY) -O binary $< $@; \
	else \
		$(OBJCOPY) -O verilog $< $@; \
	fi

# 链接.o生成.elf文件
# 这里使用 gcc 调用 ld 而非直接调用 ld
# 否则会有一些链接错误
%.elf: $(PWD)/rom.o %.o
	@$(CC) $(C_FLAGS) -T $(PWD)/memory.ld $^ -o $@ -nostdlib -lc -lm -lgcc -Wl,--no-warn-rwx-segments

# 编译.c文件
%.o: %.c
	@if echo "$@" | grep -q "fpga"; then \
		$(CC) -c $< -o $@ $(C_FLAGS); \
	else \
		$(CC) -c $< -o $@ $(C_FLAGS) -DSIM; \
	fi

# 编译rom.s文件
# $(PWD)/rom.o: $(PWD)/rom.s
%.o: %.s
	@$(AS) $(AS_FLAGS) -c $< -o $@

# 清理生成文件
clean:
	rm -f $(PWD)/rom.o $(DATAFILES) $(DUMPFILES) $(PWD)/*/*.elf $(PWD)/*/*.o

# 声明伪目标
.PHONY: all clean
