#include "alloc.s"
#include "print.s"
#include "list.s"
.section .text
#
# main
#
.globl _start
_start:
	pushl %ebp
	movl %esp, %ebp
	
	


	leave
	movl $1, %eax
	int $0x80
