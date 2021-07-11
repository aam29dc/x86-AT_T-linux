# x86-GAS-AT&T-linux-simple-function
x86 GAS (AT&amp;T) linux simple function

demonstrates use of interupts, and maintence of the stack when calling and returning from a function with parameters, etc. (c function calling convention)

to asseble, and link in linux bash terminal:

  as --32 main.asm -o main.o
  ld -melf_i386 main.o -o main
  ./main
  echo $?
