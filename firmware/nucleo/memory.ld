INCLUDE "device_STM32F401.x"

ENTRY(Reset_Handler)

/* Define memory regions */
MEMORY
{
  FLASH (rx)	: ORIGIN = 0x08000000, LENGTH = 512K
  RAM (rwx)	: ORIGIN = 0x20000000, LENGTH = 96K
  /* EEPROM (rwx)	: ORIGIN = 0x08000000 */
  /* CCMRAM (rwx)	: ORIGIN = 
  /* BATTRAM (rwx)	: ORIGIN = 0x08000000 */
}

_start_of_stack = ORIGIN(RAM) + LENGTH(RAM);
_min_stack_size = 0x400;
_min_heap_size = 0x400;

/* 
 * SECTIONS
 * 1. Defines where each program section is placed in the microcontroller's memory
 * 2. The linker assignes addresses based on teh SECTIONS command,
 *    For example, if FLASH starts at 0x0800.0000 and the .text section is placed in FLASH,
 *    the linker will assign address starting from 0x0800.0000 for the .text section.
 * 3. The ELF file guides the programming tool to correctly place the sections in the
 *    microcontroller ensuring proper execution of the code.
 */

SECTIONS
{
  .text :
  {
    /* here you should collect all executable code */
    . = ORIGIN(FLASH);
    LONG(_start_of_stack);
    KEEP(*(.isr_vector));
    *(.text)
    *(.text*)
    . = ALIGN(4);
  } > FLASH

  .rodata :
  {
    . = ALIGN(4);
    *(.rodata)
    *(.rodata*)
    . = ALIGN(4);
  } > FLASH

  /* Initialized data will be in FLASH and it will also be in RAM during runtime */
  .data :
  {
    . = ALIGN(4);
    _sidata = LOADADDR(.data); /* This returns the FLASH (LMA) */
    _sdata = .; /* start of data section in VMA (virtual memory address) */
    *(.data)
    *(.data*)
    . = ALIGN(4);
    _edata = .;
  } > RAM AT> FLASH

  /* un-initialized data will be in RAM */
  .bss :
  {
    . = ALIGN(4);
    _sbss = .;
    *(.bss)
    *(.bss*)
    . = ALIGN(4);
    _ebss = .;
  } > RAM

  .ram_usage_check :
  {
    . = ALIGN(8);
    . = . + _min_stack_size;
    . = . + _min_heap_size;
    . = ALIGN(8);
  } > RAM

}