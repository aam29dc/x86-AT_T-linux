.include "alloc.s"
.section .text
	.globl _start
	_start:
		enter $0, $0
		call allocate_init
		
		pushl $4
		call allocate
		addl $4, %esp
		
		movl $12, (%eax)
		pushl %eax
		.equ LV_1, -4
		
		pushl $4
		call allocate
		addl $4, %esp
		
		movl $21, (%eax)
		pushl %eax
		.equ LV_2, -8
		
		pushl $4
		call allocate
		addl $4, %esp
		
		movl $31, (%eax)
		pushl %eax
		.equ LV_3, -12
		
		movl LV_2(%ebp), %ebx
		
		leave
		movl $1, %eax
		int $0x80
