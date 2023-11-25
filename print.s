.section .bss
	.lcomm buffer, 256
	.lcomm buffer_len, 1
	
.section .text

# void print_num(int val)
.globl print_num
.type print_num, @function
print_num:
	pushl %ebp
	movl %esp, %ebp
	
	movl $0, %edi		# used for buffer[edi] indexing array
	movl $0, buffer_len	# init buffer length to zero
	
	movl 8(%ebp), %eax	# eax = val
	movl $0, %edx		# init edx, 0 is postive, -1 negative
	# check if val is neg
	cmpl $0, %eax
	jl is_neg
	jmp is_neg_end
	is_neg:
	movl $-1, %edx
	is_neg_end:
	# eax = val, edx = signed(-1)/unsigned(0)
	
	# loop through digits of val
	movl %edx, %ecx		# save (un)signed in ecx
	movl $0, %edi
	
	movl $10, %ebx
	d_start:
	divl %ebx		# divide eax by ebx, eax is quotient, edx is remainder (digit) to put in buffer
	
	# put digit edx into buffer
	addl $'0', %edx
	movl %edx, buffer(,%edi,1)
	incl %edi
	incl buffer_len
	movl %ecx, %edx		# restore sign
	
	cmpl $0, %eax		# after division, eax = quotient, if this is zero we have no remainder
	je d_end
	jmp d_start
	d_end:
	# buffer has string in val in reverse, buffer_len has len, %edx has sign, %edi = len, %ebx = 10, %eax = 0
	
	# if buffer_len = 1 then skip reverse
	cmpl $1, buffer_len
	jle reverse_end
	
	# reverse buffer
	movl $0, %esi			# init start index
	# if %edx is negative then put '-' if first buffer
	cmpl $0, %edx
	je d_not_neg_end
	movb $'-', buffer(,%esi,1)	# put '-' into first buffer
	incl buffer_len			# '-' is another char therefore adds + 1 to length
	incl %esi
	d_not_neg_end:
	# if neg, esi = 1, otherwise 0
	movl buffer_len, %eax
	subl %esi, %eax
	movl $0, %edx
	movl $2, %ebx
	idivl %ebx
	# if has remainder > 0 then the last iteration swap itself in place
	movl %eax, %ecx		# ecx has number of iterations
	movl buffer_len, %edi
	decl %edi
	reverse_start:
	movb buffer(,%edi,1), %al
	movb buffer(,%esi,1), %bl
	movb %al, buffer(,%esi,1)
	movb %bl, buffer(,%edi,1)
	decl %edi
	incl %esi
	decl %ecx
	cmpl $0, %ecx
	je reverse_end
	jmp reverse_start

	reverse_end:
	movl $buffer, %ecx
	movl buffer_len, %edx
	movl $1, %ebx
	movl $4, %eax
	int $0x80

	leave
	ret
