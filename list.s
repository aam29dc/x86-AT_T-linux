#include "alloc.s"
#include "print.s"
.section .data
	.equ NODE_SIZE, 8
	.equ NODE_DATA_OFFSET, 0
	.equ NODE_NEXT_OFFSET, 4
	
.section .text

# list_addNodeAtPos(NODE *head, int pos, int val)
.globl list_addNodeAtPos
.type list_addNodeAtPos, @function
list_addNodeAtPos:
	pushl %ebp
	movl %esp, %ebp
	
	# if pos = 0, then call list_prepend
	cmpl $0, 12(%ebp)
	je prepend
	
	#movl 
	
	prepend:
	pushl 12
	error_null:
	leave
	ret
	
# list_prepend(NODE *h, int val)
.globl list_prepend
.type list_prepend, @function
list_prepend:
	pushl %ebp
	movl %esp, %ebp
	
	pushl $NODE_SIZE
	call allocate		# allocate alters alot of registers, so we call it first
	addl $4, %esp		# eax = address of newhead
	
	movl 8(%ebp), %ebx	# ebx = address of head
	movl 12(%ebp), %edx	# edx = val
	movl %ebx, %ecx		# ecx = address of head
	cmpl $0, %ebx
	je error_empty_head
	
	movl (%ecx), %ecx
	movl %ecx, 4(%eax)	# newnode->next = h
	movl %edx, (%eax)	# newnode->data
	
	movl %eax, (%ebx) 	# *h = newnode;

	error_empty_head:	
	leave
	ret
	
# list_free(NODE *h)
.globl list_free
.type list_free, @function
list_free:
	pushl %ebp
	movl %esp, %ebp
	
	movl 8(%ebp), %eax
	free_start:
	cmpl $0, %eax
	je free_end
	movl 4(%eax), %ebx	# save node.next address
	
	pushl %eax		# free current node address
	call deallocate
	subl $4, %esp
	
	movl %ebx, %eax		# go to node.next address
	jmp free_start
		
	free_end:
	leave
	ret
	
# list_print(NODE *h)
.globl list_print
.type list_print, @function
list_print:
	pushl %ebp
	movl %esp, %ebp
	
	cmpl $0, 8(%ebp)
	je p_end
	
	movl 8(%ebp), %ebx
	p_start:
	
	pushl %ebx
	pushl (%ebx)
	call print_num
	addl $4, %esp
	popl %ebx
	
	movl 4(%ebx), %ebx
	cmpl $0, %ebx
	je p_end
	jmp p_start
	
	p_end:
	leave
	ret

# list_init(NODE **h, inv val)
.globl list_init
.type list_init, @function
list_init:
	pushl %ebp
	movl %esp, %ebp
	
	call allocate_init
	
	pushl $NODE_SIZE
	call allocate
	addl $4, %esp
	
	movl 12(%ebp), %ebx
	movl %ebx, NODE_DATA_OFFSET(%eax)	# node.data = val;
	movl $0, NODE_NEXT_OFFSET(%eax)		# node.next = 0;
	
	movl 8(%ebp), %ebx
	movl %eax, (%ebx)	# *h = node;
	
	leave
	ret
	
# list_append(NODE *h, inv val)
.globl list_append
.type list_append, @function
list_append:
	pushl %ebp
	movl %esp, %ebp
	
	pushl $NODE_SIZE
	call allocate
	addl $4, %esp
	# eax is the address of the new node, eax = node;
	
	movl 12(%ebp), %ebx
	movl %ebx, NODE_DATA_OFFSET(%eax)	# node.data = (ebx = val);
	movl $0, NODE_NEXT_OFFSET(%eax)		# node.next = 0;
	
	movl 8(%ebp), %ebx
	movl $0, %edi
	loop:
	movl %ebx, %ecx
	movl (%ebx,%edi,4), %ebx
	incl %edi
	cmpl $0, %ebx
	je end
	jmp loop
	end:
	# ecx is the address of the tail
	# mov address of new node into next node adddress of tail
	movl %eax, NODE_NEXT_OFFSET(%ecx)
		
	leave
	ret
