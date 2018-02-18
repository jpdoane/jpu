
###################################################################
### Setup
###################################################################

OBJDIR = obj/
SRCDIR = src/
UTILDIR = util/
MEMDIR = mem/
INCDIR = $(SRCDIR)
$(shell mkdir -p $(OBJDIR) >/dev/null)

KSRC = kernel.S exception.S kprint.S
SRC = 
SRCNAMES = $(KSRC) $(SRC)
SRCS = $(addprefix $(SRCDIR),$(SRCNAMES))

ASMSRC = $(filter %.S,$(SRCNAMES))
CSRC = $(filter %.c,$(SRCNAMES))
OBJNAMES = $(ASMSRC:.S=.o) $(CSRC:.c=.o)
OBJS = $(addprefix $(OBJDIR),$(OBJNAMES))
TARGET = jpu


#Auto dependancies
DEPDIR := .d
$(shell mkdir -p $(DEPDIR) >/dev/null)
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.Td
POSTCOMPILE = @mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d && touch $@


## MIPS Crosstools
XTOOLDIR = $(HOME)/x-tools/mipsel-jpu-elf/bin/
GCC=$(XTOOLDIR)mips-gcc
LD=$(XTOOLDIR)mips-ld
OBJDUMP=$(XTOOLDIR)mips-objdump
GCCMIPSFLAGS = -march=4k # -mtune=none
CFLAGS=-G0 -Os $(GCCMIPSFLAGS) -membedded-data  -nostdlib -I $(INCDIR)
ASMFLAGS=$(CFLAGS)
#ASMFLAGS=-G0 -O0 -fno-toplevel-reorder -fno-delayed-branch $(GCCMIPSFLAGS) -membedded-data  -nostdlib
LNFLAGS=-T $(LNSCRIPT)
LNSCRIPT=$(UTILDIR)jpu_linker.lds

## Vivado
VIVDIR = /opt/Xilinx/Vivado/2017.4/bin/
VIVFLAGS = -mode batch -nojournal -nolog -notrace
RAWBITFILE = jpu.runs/impl_2/jpu_top.bit
LOADEDBITFILE = jpu_load.bit
UPDATEMEMFLAGS = "-force"

## object and mem files for loading into bitfile
ELFFILE=$(MEMDIR)prog.elf
TEXTMEMFILE=$(MEMDIR)text.mem
DATAMEMFILE=$(MEMDIR)data.mem
KTEXTMEMFILE=$(MEMDIR)ktext.mem
KDATAMEMFILE=$(MEMDIR)kdata.mem
DAFILE=$(MEMDIR)disasm.out

#######

$(OBJDIR)%.o: $(SRCDIR)%.S $(DEPDIR)/%.d
	$(GCC) $(DEPFLAGS) $(ASMFLAGS) $< -c -o $@
	$(POSTCOMPILE)

$(OBJDIR)%.o: $(SRCDIR)%.c $(DEPDIR)/%.d
	$(GCC) $(DEPFLAGS) $(CFLAGS) $< -c -o $@
	$(POSTCOMPILE)

$(TARGET): $(OBJS)
	$(LD) $(LNFLAGS) $^ -o $@

######
$(ELFFILE): $(TARGET)
	@cp $(TARGET) $(ELFFILE)

disasm: $(TARGET)
	$(OBJDUMP) -D $<  > $(DAFILE)

loadsim: $(ELFFILE) disasm
	$(OBJDUMP) -sj .data $(ELFFILE) | $(UTILDIR)elf2mem > $(DATAMEMFILE)
	$(OBJDUMP) -sj .text $(ELFFILE) | $(UTILDIR)elf2mem > $(TEXTMEMFILE)
	$(OBJDUMP) -sj .kdata $(ELFFILE) | $(UTILDIR)elf2mem > $(KDATAMEMFILE)
	$(OBJDUMP) -sj .boot $(ELFFILE) > temp
	$(OBJDUMP) -sj .except $(ELFFILE) >> temp
	$(OBJDUMP) -sj .ktext $(ELFFILE) >> temp
	cat temp | $(UTILDIR)elf2mem > $(KTEXTMEMFILE)
	rm temp

loadbf: $(ELFFILE)
	@echo "exec updatemem $(UPDATEMEMFLAGS) --meminfo $(MEMDIR)jpu_elf.mmi \
	--data $(ELFFILE) --bit $(RAWBITFILE)  --proc jpu --out $(LOADEDBITFILE)" > $(MEMDIR)mem_elf.tcl
	$(VIVDIR)vivado $(VIVFLAGS) -source $(MEMDIR)mem_elf.tcl
	cat updatemem.log

program: 
	$(VIVDIR)vivado $(VIVFLAGS) -source $(UTILDIR)program_bf.tcl

putty:
	putty -load jpu 2>/dev/null &


#program bf and load all in one...
go: $(ELFFILE)
	@echo "exec updatemem $(UPDATEMEMFLAGS) --meminfo $(MEMDIR)jpu_elf.mmi \
	--data $(ELFFILE) --bit $(RAWBITFILE)  --proc jpu --out $(LOADEDBITFILE)" > $(MEMDIR)mem_elf.tcl
	cat $(UTILDIR)program_bf.tcl >> $(MEMDIR)mem_elf.tcl
	$(VIVDIR)vivado $(VIVFLAGS) -source $(MEMDIR)mem_elf.tcl


#######
## Build Crosstools
crosstool:
	cd crosstool && ct-ng build

clean:
	rm -rf $(OBJDIR)
	rm -rf $(DEPDIR)
	rm -f $(TARGET)
	rm -f $(LOADEDBITFILE)
	rm -f $(MEMDIR)*.elf
	rm -f $(MEMDIR)*.mem
	rm -f $(MEMDIR)*.out
	rm -f *.jou
	rm -f *.log

$(DEPDIR)/%.d: ;
.PRECIOUS: $(DEPDIR)/%.d

include $(wildcard $(patsubst %,$(DEPDIR)/%.d,$(basename $(SRCS))))
