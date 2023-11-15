# x86-AT&T-linux-GAS-notes

seperate source files can be `as` assembled alone, then `ld` linked with other object files to include/use their sources: <br>
`as alloc.s -o alloc.o`, then `as ex.s -o ex.o && ld ex.o alloc.o -o program` <br>
or you can `.include "alloc.s"` in ex.s, `#include` uses c/c++ include <br>

The C Preprocessor (Macros, etc) can be used our assembly files ('gas' GNU Assembler).

I get an error with directories from linker, so I put my asm folder in `/home/user/` (my name is user), and it links the source files, otherwise it comes up with cant find file. <br>

`as --32 main.asm -o main.o && ld -melf_i386 main.o -o main && ./main` <br>

______________________________________________________________________________________________________________________________________________________
immediate mode (`$`) on an element in the .data or .bss segment references the address. Without ($) immediate mode, it'll dereference the element to get the value. Add positive number of bytes to the address to get further elements
````assembly
.section .data
  arr: .long 0,1,2,3,4,5
  arr_size: .long arr_size - arr
.section .text
.globl _start
_start:
  movl 4, %eax           #  takes the value at address 4 and moves it into eax
  movl $4, %eax          #  moves the value 4 into eax

  movl $arr, %ebx        #  moves the address of arr into ebx
  addl $4, %ebx          #  adds 4 (bytes) to the address at ebx
  movl (%ebx), %ebx      #  replaces the address stored at ebx with the value at that address
````
______________________________________________________________________________________________________________________________________________________
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
______________________________________________________________________________________________________________________________________________________
C calling convetion for a function, the caller function (_start) calls/invokes a fuction (the callee). <br>

Caller:<br>
	1. EAX, ECX, EDX are saved caller registers, <br>
	2. parameters reverse order, onto the stack, <br>
	3. call the callee, <br>
	4. remove parameters, <br>
	5. return value in %eax, <br>
	6. restore contents of caller saved registers <br>
````assembly
.section .text
	.globl _start
	_start:
		...
		pushl %eax	# save registers before calling function
		pushl %ecx
		pushl %edx
		pushl $1	# last para
		pushl var	# first para
		call callee	# the callee
		addl $8, %esp	# remove parameters
				# return value in EAX
		popl %edx	# restore registers
		popl %ecx
		popl %eax
		...
````
Callee: <br>
	1. save old base pointer, <br>
 	2. update base pointer, <br>
  	3. allocate storage for local variables, <br>
   	4. save callee registers, <br>
    	... <br>
     	5. restore callee registers, <br>
      	6. mov stack pointer back to base pointer, <br>
       	7. restore base pointer, <br>
	8. return <br>
````assembly
	.globl callee
	.type callee, @function
	callee:
		pushl %ebp	# save old ebp for before function returns
		movl %esp, %ebp	# update base pointer
		subl $4, %esp	# allocate storage for local variable(s)

		pushl %ebx	# save callee registers
		pushl %edi
		pushl %esi
		...		# do something
		popl %esi	# restore callee registers
		popl %edi
		popl %ebx

		movl %ebp, %esp	# removes local variable storage
		popl %ebp	# restore old base pointer
		ret		# pop ret add off into eip
````
______________________________________________________________________________________________________________________________________________________
each character is a byte in a string,	%ebx holds the address of str, the first byte is the 0 character, `addl $1, %ebx` increments address to next byte, `movb (%ebx), %bl` moves the byte located at address %ebx into bl.
````assembly
.section .data
str:
	.ascii "0a\0"
str_len:
	.long str-str_len
.section .text
	.globl _start
	_start:
		movl $str, %ebx
		#addb $1, %bl
		#addw $1, %bx
		addl $1, %ebx		# ^ all do the same thing
		movb (%ebx), %bl	# dereference the value of the first byte, store it into %bl
		movl $1, %eax
		int $0x80
````
______________________________________________________________________________________________________________________________________________________
To get an address of a local variable on the stack, add ebp and the offset; this is equal to a LEA of the variable into a register. To dereference a local variable (which holds an address) in the stack, move it to a register.
````assembly
	subl $8, %esp
	.equ A, -4
	.equ B, -8
	
	# a = 123
	movl $123, A(%ebp)
	
	# b = &a
	#movl $A, B(%ebp)	# adding A's offset to EBP is the address of A
	#addl %ebp, B(%ebp)
	leal A(%ebp), %ebx	# which is equal to a LEA of A into a register, then
	movl %ebx, B(%ebp)	# moving the contents of that register back into B
	
	#*b = 30		# move the address stored in B to eax, to dereference it
	movl B(%ebp), %eax
	movl $30, (%eax)
````
______________________________________________________________________________________________________________________________________________________
`enter $0, $0` is the same as seting up the stack frame, and local variables. `leave` is the same as restoring stack frame back
````assembly
.globl func
.type func, @function
func:
	# pushl %ebp
	# movl %esp, %ebp
	# subl $4, %esp
	enter $4, $0

	leave
	# movl %ebp, %esp
	# popl %ebp
	ret	# if this were _start we'd call SYS_EXIT int instead, this moves RET address into EIP
````
______________________________________________________________________________________________________________________________________________________
brk() syscall (%ebx = 0 ) initially returns the beginning of the heap ( the first address after the end of the programs bss segment). Then (%ebx = new_address) 
returns a new_address on success rounded up/down a page (4096 bytes), and current address on failure. It sets the program break in heap, which allows for dynamic memory management.
First init heap_begin, and current_break, to current break position (on init they'll both be the beginning of the heap). Then allocate storage on heap,
by using brk to move current break position. Mark locations as used/unused. When freeing memory, just mark it unused. Moving the break position back removes available memory from the heap.
______________________________________________________________________________________________________________________________________________________
`mull` takes one operand, its unsigned multiplication by %eax, then the result is stored in %eax. <br>
`imull` takes one or two operands. If one operand then works like `mull`, otherwise `imull %ebx, %eax` is eax = eax * ebx. <br>
`divl` and `idivl` take one or two operands. Divisor = %eax, Dividend = any register, Quotient = %eax, Remainder = %edx. <br>

````assembly
	movl $123, %eax
	movl $10, %ebx
	divl %ebx	#	same as divl %ebx, %eax
	# quotient in %eax, remainder in %edx
````
______________________________________________________________________________________________________________________________________________________
