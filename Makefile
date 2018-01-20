
###################################################################
### Setup
###################################################################

UTILDIR = util/
MEMDIR = mem/
MIPSDIR = mips_src/
MIPSSRC = $(shell find $(MIPSDIR) -name '*.s')

INPUT ?= mips_src/uart_HelloWorld.s

VIVDIR = /opt/Xilinx/Vivado/2017.4/bin/
VIVFLAGS = -mode batch -nojournal -nolog -notrace
RAWBITFILE = jpu.runs/impl_1/jpu_top.bit
UPDATEMEMFLAGS = "-debug -force"

INPUTFILE=$(notdir $INPUT)
HEXFILES=$(INPUT:.s=.txt) $(INPUT:.s=.dat)
MEMFILES=$(INPUT:.s=.txt.mem) $(INPUT:.s=.dat.mem)
MEMFILE=$(INPUT:.s=.mem)


###################################################################
### Assembly Input
###################################################################

%.txt %.dat %.dat.mem %.txt.mem %.mem: %.s
	@echo "Assembling $<"
	$(UTILDIR)asm2mem $<
#	@echo "Copying mem files to $(MEMDIR)"
#	cp $(<:.s=.txt.mem) $(MEMDIR)text.mem
#	cp $(<:.s=.dat.mem) $(MEMDIR)data.mem
#	cp $(<:.s=.mem) $(MEMDIR)ram.mem

assemble: $(HEXFILES)

$(MEMDIR)ram.mem: $(INPUT:.s=.mem)
	cp $< $@

$(MEMDIR)text.mem: $(INPUT:.s=.txt.mem)
	cp $< $@

$(MEMDIR)data.mem: $(INPUT:.s=.dat.mem)
	cp $< $@

loadsim: $(MEMDIR)text.mem $(MEMDIR)data.mem

########
## Load Bitfile

jpu_load.bit: $(MEMDIR)ram.mem
	@echo "exec updatemem $(UPDATEMEMFLAGS) --meminfo $(MEMDIR)/jpu.mmi \
	--data $< --bit $(RAWBITFILE)  --proc jpu --out $@" > $(MEMDIR)mem.tcl
	$(VIVDIR)vivado $(VIVFLAGS) -source $(MEMDIR)mem.tcl
	cat updatemem.log

loadbf: jpu_load.bit

program: 
	$(VIVDIR)vivado $(VIVFLAGS) -source $(UTILDIR)program_bf.tcl

#######

clean:
	rm -f $(MIPSSRC:.s=.dat)
	rm -f $(MIPSSRC:.s=.dat.mem)
	rm -f $(MIPSSRC:.s=.txt)
	rm -f $(MIPSSRC:.s=.txt.mem)
	rm -f $(MIPSSRC:.s=.mem)
	rm -f $(MEMDIR)*.mem
	rm -f $(MEMDIR)*.reg
	rm -f jpu_load.bit
	rm -f updatemem*.jou
	rm -f updatemem*.log
