.include "linux.s"

.section .bss
.section .data
msg:
	.ascii "factorial is: "
msg_end:
.equ msg_len, msg_end - msg
.section .text

.globl _start
.globl factorial

_start:
	movl $msg, %ecx		# print msg
	movl $msg_len, %edx
	movl $STDOUT, %ebx
	movl $SYS_WRITE, %eax
	int $0x80

	pushl $5			# get factorial of 5
	call factorial
	addl $4, $esp

	movl %eax, %ebx		# return factorial with exit
	movl $SYS_EXIT, %eax
	int $0x80

.type factorial, @function
factorial:
	pushl %ebp
	movl %esp, %ebp
	movl 8(%ebp), %eax	

	loop_s:
		cmpl $1, %eax
		je loop_e
		decl %eax
		pushl %eax
		call factorial
		movl 8(%ebp), %ebx
		imull %ebx, %eax

	loop_e:
		movl %ebp, %esp
		popl %ebp
		ret