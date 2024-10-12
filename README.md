# <img src="README.assets/cpu.png" width="40" align=center /> RISCV-CPU 2022

## 引言

![wechat_screenshot](README.assets/wechat_screenshot.jpg)





## 项目说明

在本项目中，你需要使用 Verilog 语言完成一个简单的 RISC-V CPU 电路设计。Verilog 代码会以软件仿真和 FPGA 板两种方式运行。你设计的电路将运行若干测试程序并可能有输入数据，执行得到的输出数据将与期望结果比较，从而判定你的 Verilog 代码的正确性。你需要实现 CPU 的运算器与控制器，而内存等部件题面已提供代码。



### 项目阶段

- 完成 Speculative CPU 所支持的所有模块

- 在本地 Simulation 通过可执行的测试

  >  在本地 Simulation 时，部分样例运行时间可能会非常非常长，如 `heart.c` 与 `pi.c`。这些样例不会被算入 Simulation 的测试范围，但会在 FPGA 检查阶段纳入测试范围。

- 在 FPGA 上通过所有测试



### 时间安排

> 时间以上海交通大学 2024-2025 学年校历为准，Week 5 周一为 2024.10.14

每 3 周一次检查，检查时间为每周日 22:00 后，下表为检查形式与标准：

| 时间        | 检查内容                                     |
| ----------- | -------------------------------------------- |
| **Week 5**  | 仓库创建                                     |
| **Week 7**  | 完成电路设计草稿 / 各个 CPU 模块文件创建     |
| **Week 10** | 各个 CPU 模块文件基本完成，完成 `cpu.v` 连线 |
| **Week 13** | Simulation 通过所有测试点                    |
| **Week 16** | FPGA 通过所有测试点                          |



### 最终提交

你需要在github release中上传由 Vivado Synthesis 生成出的 `.bit` 文件，截止时间为第 16 周前（2025.1.5 23:59）。



### 分数构成

本作业满分为 100%。

| 评分项目        | 分数 | 说明                                     |
| --------------- | ---- | ---------------------------------------- |
| **仿真测试**    | 60%  | 通过所有仿真测试点                       |
| **FPGA 测试**   | 20%  | 通过所有 FPGA 测试点                     |
| **Code Review** | 20%  | 以面谈形式考察 CPU 原理与 HDL 的理解掌握 |





## 实现说明

### 仓库文件结构

```C++
📦RISCV-CPU
┣ 📂fpga			// FPGA 开发板相关
┣ 📂script		// 编译测试相关参考脚本
┣ 📂sim			// 仿真运行 Testbench
┣ 📂src			// HDL 源代码
┃ ┣ 📂common			// 题面提供部件源代码
┃ ┣ 📜cpu.v			// CPU 核心代码
┣ 📂testcase		// 测试点
┃ ┣ 📂fpga			// 全部测试点 
┃ ┗ 📂sim			// 仿真运行测试点
┣ 📂testspace	// 编译运行结果
┣ 📜Makefile		// 编译及测试脚本
┗ 📜README.md	// 题面文档
```

### 概述

1. 根据 [`riscv/src/cpu.v`](https://github.com/ACMClassCourses/RISCV-CPU/blob/main/riscv/src/cpu.v) 提供的接口自顶向下完成代码，其余题面代码尽量不要改动
2. 设计并实现**支持乱序执行**的 Tomasulo 架构 CPU
3. 使用 iVerilog 进行本地仿真测试（结果为 `.vcd` 文件）
4. 依照助教安排，将 Verilog 代码烧录至 FPGA 板上进行所有测试数据的测试

### 指令集

> 可参考资料见 [RISC-V 指令集](#RISC-V-指令集)

本项目使用 **RV32IC 指令集**

基础测试内容不包括 Doubleword 和 Word 相关指令、Environment 相关指令和 CSR 相关等指令。

必须要实现的指令为以下 37 个：`LUI`, `AUIPC`, `JAL`, `JALR`, `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`, `LB`, `LH`, `LW`, `LBU`, `LHU`, `SB`, `SH`, `SW`, `ADDI`, `SLLI`, `SLTI`, `SLTIU`, `XORI`, `SRLI`, `SRAI`, `ORI`, `ANDI`, `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`



## 帮助

> **这可能对你来说非常重要。**

### 文档

- Vivado 不支持 MacOS 系统，故如果使用 Mac 则必须使用虚拟机，推荐 Ubuntu Desktop。此外对于使用 Windows 电脑的同学，RISC-V Toolchain 也推荐在 Linux 系统上安装。
- 关于RISCV C拓展的相关知识，大家可以参考canvas上相关书籍 和 RISCV官方文档（https://riscv.org/technical/specifications/）



### Q & A

1. **我的 CPU 会从哪里读取指令并执行？**

   从 `0x0000000` 地址处开始执行。

2. **我的 CPU 如何停机？**

   见 `cpu.v` 中 `Specification` 部分。

3. **我的寄存器堆（Register File）需要多少个寄存器？**

   Unprivileged CPU: 32；

   Privileged CPU: 32 + 8 (CSR)。

4. **托马斯洛算法并没有硬件实现的公认唯一标准，那么本项目有什么特殊要求吗？**

   托马斯洛的要求可参考 [Wikipedia](https://en.wikipedia.org/wiki/Tomasulo%27s_algorithm#Instruction_lifecycle)，即执行一条指令需要涉及 *Issue*、*Execute*、*Write Result* 三步骤。此外，**必须要实现 *Instruction Cache*** 以确保程序运行过程中会出现多条指令的 lifecycle 重叠的情况。

5. **我该如何开始运行代码？**

   在 `riscv/` 路径下运行 `make test_sim name=000` 指令即可自动编译并运行第一个仿真测试点，测试文件均在 `riscv/testspace/` 文件夹中。

6. **`io_buffer_full`?**

   用于指示当前 ram 的 io buffer 是否已满。若已满，可能会出现 overwrite / loss。

   注意：此信号在 simulation 部分始终为 low (false)，但在 FPGA 上会有高低变化。

7. **`in_rdy`?**

   用于指示当前hci总线是否为active (可工作)，若否，则cpu应当pause。

8. **运行测试过程中 build 报错？**

   请考虑以下几点：

   - 目录错误

     脚本运行目录应当为 `riscv/` 文件夹

   - 环境缺失，如 `cannot find module -lgcc ...`

     **在配置了riscv-toolchains 的环境下，应当可以正常 build。**

     **请检查连接了 FPGA 的系统是否配置了 riscv-toolchains，若没有，你也可以使用现成的编译结果。**

9. **To be continued...**





----

> 以下为附录内容。





## 附录 A

### RISC-V 指令集

- 官网 https://riscv.org/
- [官方文档下载页面](https://riscv.org/technical/specifications/)
  - 基础内容见 Volume 1, Unprivileged Spec
  - 特权指令集见 Volume 2, Privileged Spec
- 非官方 [Read the Docs 文档](https://msyksphinz-self.github.io/riscv-isadoc/html/index.html)

- 非官方 Green Card，[PDF 下载链接](https://inst.eecs.berkeley.edu/~cs61c/fa17/img/riscvcard.pdf)

### RISC-V C and C++ Cross-compiler

- https://github.com/riscv-collab/riscv-gnu-toolchain 根据该 Repo 教程安装
- 请注意下载需要 6.6G 空间，安装内容大小为 1G 左右。

### 使用 FPGA 板运行代码

- **Vivado**

  - 你需要该软件将 Verilog 代码编译为可以烧录至 FPGA 板的二进制文件

  - Vivado 安装后软件整体大小达 30G 左右，请准备足够硬盘空间

- **Serial Communication Library**

  - 程序与 FPGA 板通过 USB 通讯过程中使用该库
  - 安装方式参见本仓库 Submodule


