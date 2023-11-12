# x86-GAS-AT&T-linux-notes

to assemble, link and run in linux bash terminal (gcc):

  `as --32 main.asm -o main.o && ld -melf_i386 main.o -o main && ./main`

````assembly
  movl 4, %eax          #  takes the value at address 4 and moves it into eax
  movl $4, %eax         #  moves the value 4 into eax
````
immediate mode ($) on an element in the .data or .bss segment references the address, alone without immediate mode, it'll dereference the element to get the value. Add positive number of bytes to the address to get further elements
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
`push` is equal to a `sub` and then a `mov`, a `pop` a `mov` then an `add`. In the `_start` function `movl %esp, %ebp` to setup the base pointer; to be able to reference it. We should be able to replace -4(%ebp) with (%esp), but we use ebp as our reference, and add/sub to esp to move it.
````assembly
.section .text
	.globl _start
	_start:
		movl %esp, %ebp		#	different setup for the _start function, without this i can't use ebp
					#	as a reference
		
		#push $123
		subl $4, %esp
		movl $123, -4(%ebp)
		
		# mov into a register, do something to it, move it back
		movl -4(%ebp), %ebx
		incl %ebx
		movl %ebx, -4(%ebp)
		
		# value gets echo'd through this register
		movl -4(%ebp), %ebx
		
		#pop
		addl $4, %esp
		movl $1, %eax
		int $0x80
````
