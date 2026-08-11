ENTRY(_start)

SECTIONS {
  _pmem_start = 0x00000000;
  . = _pmem_start;
  .text : {
    *(entry)
    *(.text*)
  }
  .rodata : {
    *(.rodata*)
  }
  .data : {
    *(.data*)
  }
  .bss : {
    *(.bss*)
    *(.sbss*)
  }

  . = ALIGN(16);
  . = . + 0x4000;
  _stack_pointer = .;
}
