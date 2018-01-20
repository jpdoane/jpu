# jpu - 32bit mips ISA CPU

This is a 32 bit mips ISA CPU. Some of the code is borrowed from the CMU ece447 labs found here: http://www.ece.cmu.edu/~ece447/s15/doku.php, although I plan to eventually replace all borrowed code with my own.  The CMU ece447 course lectures and lab files are all online and are a really great resource for learning about computer architecture.

The CPU is written in Verilog and runs on an Xilinx Artix 7 (I'm using the Digilent Arty 7 board).
But it should be straightforward to get it to run on any small FPGA.  The Xilinx Vivado project is included, and runs on the (free) Xilinx web-pack license. Assembly is performed with spim, which can be optained here: http://spimsimulator.sourceforge.net/

