#include "../../omni.h"

//Initialize all the function pointers in one place.
void Omni_InitGlobal(
        omni_alloc_func_t* alloc_func, 
        omni_realloc_func_t* realloc_func, 
        omni_free_func_t* free_func, 
        omni_print_debug_func_t* print_debug_func, 
        omni_print_str_func_t* print_str_func, 
        omni_print_float_func_t* print_float_func, 
        omni_print_int_func_t* print_int_func,
        omni_get_samplerate_func_t* get_samplerate_func, 
        omni_get_bufsize_func_t* get_bufsize_func
    )
{
    Omni_InitAlloc(alloc_func, realloc_func, free_func);
    Omni_InitPrint(print_debug_func, print_str_func, print_float_func, print_int_func);
    Omni_InitGetSamplerateGetBufsize(get_samplerate_func, get_bufsize_func);
}