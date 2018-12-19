
###################################################################
### Setup
###################################################################

OBJDIR = obj/
SRCDIR = src/
UTILDIR = util/
MEMDIR = mem/
INCDIR = $(SRCDIR)
$(shell mkdir -p $(OBJDIR) >/dev/null)

KSRC = #kernel.S exception.S kprint.S
SRC = test.s
SRCNAMES = $(KSRC) $(SRC)
SRCS = $(addprefix $(SRCDIR),$(SRCNAMES))

o1 = $(SRCNAMES:.s=.o)
o2 = $(o1:.S=.o)
OBJNAMES = $(o2:.c=.o)
OBJS = $(addprefix $(OBJDIR),$(OBJNAMES))
TARGET = jpu

#Auto dependancies
DEPDIR := .d
$(shell mkdir -p $(DEPDIR) >/dev/null)
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.Td
POSTCOMPILE = @touch $(DEPDIR)/$*.Td && mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d 2>/dev/null && touch $@


## RISC-V Crosstools
CC = riscv32-unknown-elf-gcc
CFLAGS=-Os -nostdlib -I $(INCDIR)

OBJDUMP = riscv32-unknown-elf-objdump
LD = riscv32-unknown-elf-ld
ASMFLAGS=$(CFLAGS)
LNFLAGS=-T $(LNSCRIPT)
LNSCRIPT=$(UTILDIR)jpu_linker.lds

## Vivado
VIVDIR = /opt/Xilinx/Vivado/2018.2/bin/
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

$(OBJDIR)%.o: $(SRCDIR)%.s $(DEPDIR)/%.d
	$(CC) $(DEPFLAGS) $(ASMFLAGS) $< -c -o $@
	$(POSTCOMPILE)

$(OBJDIR)%.o: $(SRCDIR)%.S $(DEPDIR)/%.d
	$(CC) $(DEPFLAGS) $(ASMFLAGS) $< -c -o $@
	$(POSTCOMPILE)

$(OBJDIR)%.o: $(SRCDIR)%.c $(DEPDIR)/%.d
	$(CC) $(DEPFLAGS) $(CFLAGS) $< -c -o $@
	$(POSTCOMPILE)

$(TARGET): $(OBJS)
	$(LD) $(LNFLAGS) $^ -o $@

######
$(ELFFILE): $(TARGET)
	@cp $(TARGET) $(ELFFILE)

disasm: $(TARGET)
	$(OBJDUMP) -D $<  > $(DAFILE)

mem: 	$(ELFFILE) disasm
	-$(OBJDUMP) -s $(ELFFILE) | $(UTILDIR)elf2mem data > $(DATAMEMFILE) 
	-$(OBJDUMP) -s $(ELFFILE) | $(UTILDIR)elf2mem text > $(TEXTMEMFILE)
	-$(OBJDUMP) -s $(ELFFILE) | $(UTILDIR)elf2mem kdata > $(KDATAMEMFILE)
	-$(OBJDUMP) -s $(ELFFILE) | $(UTILDIR)elf2mem boot except ktext > $(KTEXTMEMFILE)

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
