# x86-GAS-AT&T-linux-notes

to assemble, link and run in linux bash terminal (gcc):
`as --32 main.asm -o main.o && ld -melf_i386 main.o -o main && ./main`

______________________________________________________________________________________________________________________________________________________
immediate mode (`$`) on an element in the .data or .bss segment references the address, alone without immediate mode, it'll dereference the element to get the value. Add positive number of bytes to the address to get further elements
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
C calling convetion for a function, the caller function (_start) calls/invokes a fuction (the callee).

Caller:
	1. EAX, ECX, EDX are saved caller registers, 
	2. parameters reverse order, onto the stack, 
	3. call the callee, 
	4. remove parameters, 
	5. return value in %eax, 
	6. restore contents of caller saved registers
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
Callee:
	1. save old base pointer, 
 	2. update base pointer, 
  	3. allocate storage for local variables, 
   	4. save callee registers, 
    	...
     	5. restore callee registers, 
      	6. mov stack pointer back to base pointer, 
       	7. restore base pointer, 
	8. return
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
	ret
````
