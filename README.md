# x86-GAS-AT&T-linux-notes

to assemble, link and run in linux bash terminal (gcc):

  `as --32 main.asm -o main.o && ld -melf_i386 main.o -o main && ./main`

# 12321321 #

````assembly
.section .data
  arr: .long 0,1,2,3,4,5
  arr_size: .long arr_size - arr
.section .text
.globl _start
_start:
  movl $arr, %ebx        #  moves the address of arr into ebx
  addl $4, %ebx          #  adds 4 (bytes) to the address at ebx
  movl (%ebx), %ebx      #  replaces the address stored at ebx with the value at that address
````
