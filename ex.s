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
	subl $4, %esp		# NODE *h = 0;
	movl $0, -4(%ebp)
	
	movl %esp, %ebx		# ebx = &h;
	
	pushl $1
	pushl %ebx
	call list_init		# this calls allocate_init which must be called before any allocations
	popl %ebx
	addl $4, %esp
	
	pushl $2
	pushl %ebx
	call list_prepend
	popl %ebx
	addl $4, %esp		# address of newhead in eax
	
	pushl $3
	pushl $1
	pushl %ebx
	call list_addNodeAtPos
	popl %ebx
	addl $4, %esp
	
	pushl (%ebx)
	call list_print
	addl $4, %esp
 
	leave
	movl $1, %eax
	int $0x80
