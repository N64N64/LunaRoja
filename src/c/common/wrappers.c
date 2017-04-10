#include <stdio.h>

int fseek_wrapper(FILE *f, long offset, int whence)
{
    return fseek(f, offset, whence);
}
