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
  .MIPS.abiflags : { *(.MIPS.abiflags) }
/*  .other : { *(.MIPS.abiflags) }*/
}
