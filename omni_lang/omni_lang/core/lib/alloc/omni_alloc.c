//#include "stdio.h"
//#include "malloc.h"

typedef unsigned long size_t; 

typedef void* alloc_func_t(size_t inSize);
alloc_func_t* omni_alloc_func; // = malloc; //Default with malloc

typedef void* realloc_func_t(void *inPtr, size_t inSize);
realloc_func_t* omni_realloc_func; // = realloc; //Default with realloc

typedef void  free_func_t(void *inPtr);
free_func_t* omni_free_func; // = free; //Default it with free

typedef int print_func_t(const char* formatString, ...);
print_func_t* omni_print_func; // = printf; //Default it with printf

void Omni_Init(alloc_func_t* alloc_func, realloc_func_t* realloc_func, free_func_t* free_func, print_func_t* print_func)
{
    omni_alloc_func   = alloc_func;
    omni_realloc_func = realloc_func;
    omni_free_func    = free_func;
    omni_print_func   = print_func;
    omni_print_func("Called Omni_Init\n");
}

void* omni_alloc_C(size_t inSize)
{
    omni_print_func("Calling omni_alloc_C with size: %d\n", inSize);
    return omni_alloc_func(inSize);
}

void* omni_alloc0_C(size_t inSize)
{
    omni_print_func("Calling omni_alloc0_C with size: %d\n", inSize);
    void* memory = omni_alloc_func(inSize);
    if(memory)
        memset(memory, 0, inSize);
    return memory;
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

int omni_print(const char* formatString, ...)
{
    return omni_print_func(formatString);
}