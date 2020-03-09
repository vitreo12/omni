//#include "stdio.h"
//#include "malloc.h"

#include "omni_alloc.h"
#include "../print/omni_print.h"

void* omni_alloc_C(size_t inSize)
{
    omni_print_func("Calling omni_alloc_C with size: %d\n", inSize);
    return omni_alloc_func(inSize);
}

void* omni_realloc_C(void *inPtr, size_t inSize)
{
    omni_print_func("Calling omni_realloc_C with size: %d\n", inSize);
    return omni_realloc_func(inPtr, inSize);
}

void omni_free_C(void* inPtr)
{
    omni_print_func("Calling omni_free_C\n");
    omni_free_func(inPtr);
}