#include "../../omni.h"

//Global get_samplerate / get_bufsize functions. These are set in Omni_InitGetSamplerateGetBufsize
omni_get_samplerate_func_t* omni_get_samplerate_func;
omni_get_bufsize_func_t*    omni_get_bufsize_func;

OMNI_DLL_EXPORT void Omni_InitGetSamplerateGetBufsize(omni_get_samplerate_func_t* get_samplerate_func, omni_get_bufsize_func_t* get_bufsize_func)
{
    omni_get_samplerate_func = get_samplerate_func;
    omni_get_bufsize_func    = get_bufsize_func;
}

double omni_get_samplerate_C(void)
{
    return omni_get_samplerate_func();
}

int omni_get_bufsize_C(void)
{
    return omni_get_bufsize_func();
}