#include <stdio.h>

extern int _myPrintf(const char* format, ...);
//extern int _test(long long param, ...);
int main(void)
{
    _myPrintf("%c%c", '!', '\n');

    printf("%s\n\n", "This is another string");

    return 0;
}
//gcc -no-pie -o main main.c printf.o
//nasm -f elf64 printf.s
//ld printf.o -o printf


