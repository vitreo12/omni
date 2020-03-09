#include "omni_samplerate_bufsize.h"

double omni_get_samplerate_C(void)
{
    return omni_get_samplerate_func();
}

int omni_get_bufsize_C(void)
{
    return omni_get_bufsize_func();
}