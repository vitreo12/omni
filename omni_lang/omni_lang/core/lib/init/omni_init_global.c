#include "../../omni.h"

//Initialize all the function pointers in one place.
void Omni_InitGlobal
    (
        omni_alloc_func_t*          alloc_func, 
        omni_realloc_func_t*        realloc_func, 
        omni_free_func_t*           free_func, 
        omni_print_func_t*          print_func,
        omni_get_samplerate_func_t* get_samplerate_func,
        omni_get_bufsize_func_t*    get_bufsize_func
    )
{
    Omni_InitAlloc(alloc_func, realloc_func, free_func);
    Omni_InitPrint(print_func);
    Omni_InitGetSamplerateGetBufsize(get_samplerate_func, get_bufsize_func);

    omni_print_func_t* omni_print_func = get_omni_print_func();
    size_t something = 1000;
    if(omni_print_func)
        omni_print_func("Called OmniInitGlobal: %lu \n", something); //Weird values in Max's post...
}