/*MEMORY
  {
    RAM_TEXT : ORIGIN = 0x00400000, LENGTH = 0x400000
    RAM_DATA : ORIGIN = 0x10000000, LENGTH = 0x400000
  }

REGION_ALIAS("REGION_TEXT", RAM_TEXT);
REGION_ALIAS("REGION_DATA", RAM_DATA);
*/

SECTIONS
{
  . = 0x00400000;
  .text :
  {
	*(entry)
	*(.text*)
  }
  . = 0x10000000;
  .data : { *(.sdata* .rodata* .data* .bss) }  
  . = 0x80000000;
  .boot :
  {
	*(bootstrap)
	*(.boot*)
  }
  . = 0x80000180;
  .except :
  {
	*(except_hdl)
	*(.except*)
  }
  .ktext :
  {
	*(.ktext*)
  }
  . = 0x90000000;
  .kdata :
  {
	*(.kdata*)
  }

/*  .other : { *(.MIPS.abiflags) }*/
}
