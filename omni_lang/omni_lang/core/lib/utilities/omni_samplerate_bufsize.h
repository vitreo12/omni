#ifndef _OMNI_SAMPLERATE_BUFSIZE_
#define _OMNI_SAMPLERATE_BUFSIZE_

typedef double get_samplerate_func_t();
typedef int    get_bufsize_func_t();

get_samplerate_func_t* omni_get_samplerate_func;
get_bufsize_func_t*    omni_get_bufsize_func;

#endif