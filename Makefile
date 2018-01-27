
###################################################################
### Setup
###################################################################

SRCDIR = src/

UTILDIR = util/
MEMDIR = mem/
OBJDIR = obj/

INPUT ?= src/echo.c

LNSCRIPT=$(UTILDIR)jpu_linker.lds
GCC=mipsel-unknown-elf-gcc
OBJDUMP=mipsel-unknown-elf-objdump
GCCFLAGS=-G0 -Os -membedded-data -nostdlib -T $(LNSCRIPT)

VIVDIR = /opt/Xilinx/Vivado/2017.4/bin/
VIVFLAGS = -mode batch -nojournal -nolog -notrace
RAWBITFILE = jpu.runs/impl_1/jpu_top.bit
LOADEDBITFILE = jpu_load.bit
UPDATEMEMFLAGS = "-force"

ELFFILE=$(MEMDIR)prog.elf
TEXTMEMFILE=$(MEMDIR)text.mem
DATAMEMFILE=$(MEMDIR)data.mem


#######
##

$(OBJDIR)echo.o: $(MIPSDIR)echo.c $(MIPSDIR)uart.c
	$(GCC) $(GCCFLAGS) $^ -o $@
	cp $@ $(ELFFILE)

####

$(ELFFILE): $(OBJDIR)echo.o

loadsim:
	$(OBJDUMP) -sj .data $(ELFFILE) | $(UTILDIR)/elf2mem > $(DATAMEMFILE)
	$(OBJDUMP) -sj .text $(ELFFILE) | $(UTILDIR)/elf2mem > $(TEXTMEMFILE)

loadbf:
	@echo "exec updatemem $(UPDATEMEMFLAGS) --meminfo $(MEMDIR)jpu_elf.mmi \
	--data $(ELFFILE) --bit $(RAWBITFILE)  --proc jpu --out $(LOADEDBITFILE)" > $(MEMDIR)mem_elf.tcl
	$(VIVDIR)vivado $(VIVFLAGS) -source $(MEMDIR)mem_elf.tcl
	cat updatemem.log

program: 
	$(VIVDIR)vivado $(VIVFLAGS) -source $(UTILDIR)program_bf.tcl

#######

clean:
	rm -f $(LOADEDBITFILE)
	rm -rf $(OBJDIR)
	rm -f $(MEMDIR)*.elf
	rm -f $(MEMDIR)*.mem
	rm -f *.jou
	rm -f *.log
