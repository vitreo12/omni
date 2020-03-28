#include "../../omni.h"

//Global allocation functions. These are set from Omni_InitAlloc
omni_alloc_func_t*   omni_alloc_func;     // = malloc;  //Default with malloc
omni_realloc_func_t* omni_realloc_func; // = realloc; //Default with realloc
omni_free_func_t*    omni_free_func;       // = free;    //Default it with free

void Omni_InitAlloc(omni_alloc_func_t* alloc_func, omni_realloc_func_t* realloc_func, omni_free_func_t* free_func)
{
    omni_alloc_func   = alloc_func;
    omni_realloc_func = realloc_func;
    omni_free_func    = free_func;
}

void* omni_alloc_C(size_t in_size)
{
    omni_print_str_val_func_t* omni_print_str_val_func = get_omni_print_str_val_func();
    if(omni_print_str_val_func)
        omni_print_str_val_func("Calling omni_alloc_C with size: ", in_size);

    return omni_alloc_func(in_size);
}

void* omni_realloc_C(void *in_ptr, size_t in_size)
{
    omni_print_str_val_func_t* omni_print_str_val_func = get_omni_print_str_val_func();
    if(omni_print_str_val_func)
        omni_print_str_val_func("Calling omni_realloc_C with size: ", in_size);

    return omni_realloc_func(in_ptr, in_size);
}

void omni_free_C(void* in_ptr)
{
    omni_print_str_val_func_t* omni_print_str_val_func = get_omni_print_str_val_func();
    if(omni_print_str_val_func)
        omni_print_str_val_func("Calling omni_free_C: ", 0);

    omni_free_func(in_ptr);
}