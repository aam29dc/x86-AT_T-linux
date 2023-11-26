# x86-AT&T-linux-GAS-notes

seperate source files can be `as` assembled alone, then `ld` linked with other object files to include/use their sources: <br>
`as alloc.s -o alloc.o`, then `as ex.s -o ex.o && ld ex.o alloc.o -o program` <br>
or you can `.include "alloc.s"` in ex.s, `#include` uses c/c++ include <br>

The C Preprocessor (Macros, etc) can be used our assembly files ('gas' GNU Assembler).

I get an error with directories from linker, so I put my asm folder in `/home/user/` (my name is user, this directory is referenced as Home) and it links the source files, otherwise it comes up with cant find file. <br>

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
`divl` and `idivl` take one or two operands. Dividend = %edx:%eax (EDX:EAX is 64 bits made up of two 32 bit registers.), Divisor = any (32bit) register, Quotient = %eax, Remainder = %edx. <br>

````assembly
	movl $0, %edx		# sign is positive, so 0, otherwise movl $-1, %edx, then movl $-123, %eax, with idiv
	movl $123, %eax		# dividend
	movl $10, %ebx		# divisor
	divl %ebx		# same as divl %ebx, %eax
	# quotient in %eax, remainder in %edx
````
______________________________________________________________________________________________________________________________________________________
buffers are bytes in length, when writing to a buffer that is an array of chars (bytes), be sure to use `movb` otherwise a higher order mov like `movl` will overwrite the buffer 4 bytes over.
````assembly
.section .bss
	.lcomm buffer, 256
.section .text
	...
	movb $1, buffer(,%edi,1)	# 	writes the first byte of buffer, with a value of 1
	...
	movl $1, buffer(,%edi,1)	#	writes the first 4 bytes of buffer, with a value of 1
````
______________________________________________________________________________________________________________________________________________________
Using the C library in assembly:<br>

Use `main` instead of `_start`, and use `call exit`. printf(...) is a variadic function, which takes a variable number of parameters, which uses `%al`, so set to 0 by `xor %eax, %eax` before a call to printf to not use vector registers. <br>
The `call` instruction pushes 8 bytes (return address) onto the stack, but the Stack Pointer must be aligned by 16-bytes; a `push %rax` and `pop %rax` before and after a call is required to realign the stack pointer, otherwise resulting in a segmentation fault. In main we can just `ret`.<br>
First parameter goes in `rdi`, <br>
and second parameter goes into `rsi`.<br>
<br>
to assemble, link, and run I used gcc: `gcc -no-pie -o file file.s && file`. gcc links in the c library, so no need to `#include`.<br>
````assembly
.section .data
msg:
	.string "%d\n"
.section .text
.globl main
main:
	pushl rax
	mov $msg, %rdi
	mov $123, %rsi
	call printf
	pop %rax
	ret
````
______________________________________________________________________________________________________________________________________________________
Different instructions are used for 32 or 64bit mode when using the FPU. <br>

In 32bit mode, we have 8 FP registers named `st(0)` to `st(7)` or `mm0` to `mm7`, st(0) always points to the top of the stack.<br>
--Operations on floating point numbers are done in these registers; returns are stored in st(0); local variables use `fstp -4(%ebp)` to pop off FP stack into memory location on regular stack.
--immediate values aren't used for float instructions, instead use memory. There are instructions for pushing value 0 `fldz`, 1 `fld1` to top of FP stack, then pop `fstps` this off into a register.
--When instructions are used like `flds var1` (where the s denotes single precision, and d double precision) this pushes the value var1 onto the FP Stack (therefore goes in st(0)/mm0); another `flds var2`, and st(0) now has var2, and st(1) has var1.<br>
--`fstps var1` pops whats ontop of the FP Stack st(0) into memory location var1. <br>
````assembly
.section .data
f1:	.float 1.23
f2:	.float 9.87
f3:	.float 55.5
format:		.string "%f\n"
.section .text
	.globl main
	main:
		pushl %rax		# for call printf, we'll be using 64bit arch to covert our float to a double
		flds f1
		flds f2
		flds f3			# after this instruction, st(0) holds f3, and st(2) holds f1
		fmul %st(1), %st(0)	# only certain FPU registers can be used. multplies st(0) * st(1) and stores it in st(0)
		fstps f1		# pop off top of FPU stack, which is st(0), into memory location f1

		movsd f1, %xmm0		# s = single, d = double word, q = quad word
		cvrtss2sd %xmm0, %xmm0	# convert single precision to double precision and store it

		movq format, %rdi	# string goes in rdi
		movb $1, %al		# we're taking 2 parameters to printf
					# printf knows to llok in xmm0 for parameter
		call printf
		pop %rax		# realign to 16 bytes otherwise segmentation fault

		ret
````
______________________________________________________________________________________________________________________________________________________
In 64bit mode, there are 16 FP registers (along w/ previous) named `xmm0` to `xmm15`.<br>
--We don't push and pop values onto a FP stack, we just use `movss`,`movsd` either s/d for single/double precision, but this mov cannot use immediate values, instead a constant must be stored in memory.<br>
--`cvtss2sd %xmm0, %xmm0` converts a single precision float to a double precision, and stores it back into `xmm0`<br>
--`movsd name(%rip), %xmm0` is the same as `movsd name, %xmm0`<br>
````assembly
.section .data
d1:	.double 1.23
d2:	.double 9.87
d3:	.double 55.5
.section .text
	.globl main
	main:
		push %rax
		
		call printf
		pop %rax
		ret
````
