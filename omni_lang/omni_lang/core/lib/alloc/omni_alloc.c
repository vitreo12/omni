#include "omni_alloc.h"
#include "../print/omni_print.h"

//Global allocation functions. These are set from OmniInitAlloc
alloc_func_t* omni_alloc_func;     // = malloc;  //Default with malloc
realloc_func_t* omni_realloc_func; // = realloc; //Default with realloc
free_func_t* omni_free_func;       // = free;    //Default it with free

void OmniInitAlloc(alloc_func_t* alloc_func, realloc_func_t* realloc_func, free_func_t* free_func)
{
    omni_alloc_func   = alloc_func;
    omni_realloc_func = realloc_func;
    omni_free_func    = free_func;
}

void* omni_alloc_C(size_t inSize)
{
    print_func_t* omni_print_func = get_omni_print_func();
    if(omni_print_func)
        omni_print_func("Calling omni_alloc_C with size: %d\n", (int)inSize);

    return omni_alloc_func(inSize);
}

void* omni_realloc_C(void *inPtr, size_t inSize)
{
    print_func_t* omni_print_func = get_omni_print_func();
    if(omni_print_func)
        omni_print_func("Calling omni_realloc_C with size: %lu\n", inSize);

    return omni_realloc_func(inPtr, inSize);
}

void omni_free_C(void* inPtr)
{
    print_func_t* omni_print_func = get_omni_print_func();
    if(omni_print_func)
        omni_print_func("Calling omni_free_C\n");

    omni_free_func(inPtr);
}