#include "../print/omni_print.h"
#include "../alloc/omni_alloc.h"
#include "../utilities/omni_samplerate_bufsize.h"

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
    omni_alloc_func          = alloc_func;
    omni_realloc_func        = realloc_func;
    omni_free_func           = free_func;
    omni_print_func          = print_func;
    omni_get_samplerate_func = get_samplerate_func;
    omni_get_bufsize_func    = get_bufsize_func;

    omni_print_func("Called Omni_Init\n");
}