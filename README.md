# jpu - 32bit RISC-V ISA CPU

This is a 32 bit CPU with a risc-v ISA (rv32i).

The CPU is written in Verilog and runs on an Xilinx Artix 7 (I'm using the Digilent Arty 7 board). But it should be straightforward to get it to run on any small FPGA.  The Xilinx Vivado project is included, and runs on the (free) Xilinx web-pack license.

The risc-v toolchain is available here

https://riscv.org/software-tools/risc-v-gnu-compiler-toolchain/

and should be configured with the following options
$$ ./configure --prefix=/opt/riscv 