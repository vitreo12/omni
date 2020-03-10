#include "../alloc/omni_alloc.h"
#include "../print/omni_print.h"
#include "../utilities/omni_samplerate_bufsize.h"

//Initialize all the function pointers in one place.
void OmniInitGlobal
    (
        alloc_func_t* alloc_func, 
        realloc_func_t* realloc_func, 
        free_func_t* free_func, 
        print_func_t* print_func,
        get_samplerate_func_t* get_samplerate_func,
        get_bufsize_func_t* get_bufsize_func
    )
{
    OmniInitAlloc(alloc_func, realloc_func, free_func);
    OmniInitPrint(print_func);
    OmniInitGetSamplerateGetBufsize(get_samplerate_func, get_bufsize_func);

    print_func_t* omni_print_func = get_omni_print_func();
    size_t something = 1000;
    if(omni_print_func)
        omni_print_func("Called OmniInitGlobal: %lu \n", something); //Weird values in Max's post...
}