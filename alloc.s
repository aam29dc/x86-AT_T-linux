.section .data
	heap_begin:	.long	0
	current_break:	.long	0
	
	.equ HEADER_SIZE,	8
	.equ HDR_AVAIL_OFFSET,	0
	.equ HDR_SIZE_OFFSET,	4
	
	.equ UNAVA,		0
	.equ AVA,		1
	.equ SYS_BRK,		45
	.equ LINUX_SYSCALL,	0x80
	
.section .text

		
	#
	# no parameters, and no return value, changes heap_begin & current_break values
	#
	.globl allocate_init
	.type allocate_init, @function
	allocate_init:
		pushl %ebp
		movl %esp, %ebp
		
		movl $SYS_BRK, %eax		# if brk is called with 0 in %ebx
		movl $0, %ebx			# it returns the last usable address in %eax
		int $LINUX_SYSCALL
		
		incl %eax			# %eax has last valid address, get the memory afer that
		
		movl %eax, current_break	# store the current break
		movl %eax, heap_begin		# store it as our first address
						# this will cause the alloc function to get more memory
						# the first time it is run
		movl %ebp, %esp
		popl %ebp
		ret
		
	#
	# Used to grab a section of memory. Checks to see if there are any free blocks, and, if not
	# it ask Linux for a new one.
	#
	# one parameter (the size of the memory block to allocate), returns the address of
	# the allocated block in %eax, if there is no memory available returns 0 in %eax
	#
	# We scan through each memory region starting with heap_begin. We look at the size of
	# each one, and if it has been allocated. If it's big enough for the requested size, and if its
	# available, it grabs that one. If it doesn't find a region large enough, it asks Linux for more
	# memory. In that case, it moves current_break up.
	#
	.globl allocate
	.type allocate, @function
	.equ ST_MEM_SIZE, 8			# stack position of the memory size to allocate (parameter)
	allocate:
		pushl %ebp
		movl %esp, %ebp
		
		movl ST_MEM_SIZE(%ebp), %ecx	# %ecx holds the size we want to allocate
		movl heap_begin, %eax		# %eax holds the current search location
		movl current_break, %ebx	# %ebx holds the current break
		
		alloc_loop_begin:		# here we iterate through each memory region
		cmpl %ebx, %eax				# need more memory if these are equal
		je move_break
		
		movl HDR_SIZE_OFFSET(%eax), %edx	# grab the size of this memory
		cmpl $UNAVA, HDR_AVAIL_OFFSET(%eax)	# if unavailable, goto the next one
		je next_location
		
		cmpl %edx, %ecx				# compare the size. If its big enough,
		jle allocate_here			# goto allocate_here
		
		next_location:
		addl $HEADER_SIZE, %eax			# the total size of the memory region
		addl %edx, %eax				# is the sum of the size requested
							# (current stored in %edx), plus another
							# 8 bytes for the header ( 4 for the
							# AVA/UNAVA flag, and 4 for the size of
							# the region). So, adding %edx and $8
							# to %eax will get the address of the
							# next memory region
							
		jmp alloc_loop_begin			# go look at the next location
		
		allocate_here:				# if we've made it here, that means
							# that the region header of the region
							# to allocate is in %eax
							
		movl $UNAVA, HDR_AVAIL_OFFSET(%eax)	# mark space as unavailable
		addl $HEADER_SIZE, %eax			# move %eax past the header to the
							# usable memory (since thats what
							# we return )
		
		movl %ebp, %esp
		popl %ebp
		ret
		
		move_break:				# if we've made it here, that means that
							# we have exhausted all addressable memory,
							# and we need to ask for more.
							# %ebx holds the current endpoint of the data,
							# and %ecx holds its size
							
		addl $HEADER_SIZE, %ebx			# add space for the headers structure
		addl %ecx, %ebx				# add space to the break for the data requested
		
							# now its time to ask Linux for more memory
		pushl %eax				# save needed registers
		pushl %ecx
		pushl %ebx
		
		movl $SYS_BRK, %eax			# %ebx has the requested break point
		int $LINUX_SYSCALL			# under normal conditions, this should
							# return the new break in %eax, which will
							# be either 0 if its fails, or it will be
							# equal to or larger than we asked for. We
							# don't care in this program where it actually
							# sets the break, so as long as %eax isn't 0,
							# we don't care what it is
		
		cmpl $0, %eax
		je error
		
		popl %ebx
		popl %ecx
		popl %eax
		
		movl $UNAVA, HDR_AVAIL_OFFSET(%eax)	# set this memory as unavailable, since we're
							# about to give it away
							
		movl %ecx, HDR_SIZE_OFFSET(%eax)	# set the size of the memory
		
		addl $HEADER_SIZE, %eax			# move %eax to the actual start of usable memory
		
		movl %ebx, current_break		# save the new break
		
		movl %ebp, %esp
		popl %ebp
		ret
		
		error:
		movl $0, %eax
		movl %ebp, %esp
		popl %ebp
		ret
	
	#
	# The purpose of this function is to give back a region of memory to the pool, after were done
	# using it.
	# 
	# The only parameter is the address of the memory we want to return to the memory pool.
	# No return value
	#
	# If you remember, we actually hand the program the start of the memory that they can use, which
	# is 8 storage locations after the actual start of the memory region. All we have to do is go back
	# 8 locations and mark that memory as available, so that the allocate function knows it can use it.
	#
		
	.globl deallocate
	.type deallocate, @function
	.equ ST_MEMORY_SEG, 4
	deallocate:
		movl ST_MEMORY_SEG(%esp), %eax
		subl $HEADER_SIZE, %eax
		movl $AVA, HDR_AVAIL_OFFSET(%eax)
		ret
