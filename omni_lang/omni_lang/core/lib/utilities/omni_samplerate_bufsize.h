#ifndef _OMNI_SAMPLERATE_BUFSIZE_
#define _OMNI_SAMPLERATE_BUFSIZE_

#ifdef __cplusplus
extern "C" {
#endif

typedef double get_samplerate_func_t();
//extern get_samplerate_func_t* omni_get_samplerate_func;

typedef int    get_bufsize_func_t();
//extern get_bufsize_func_t*    omni_get_bufsize_func;

extern void Omni_InitGetSamplerateGetBufsize(get_samplerate_func_t* get_samplerate_func, get_bufsize_func_t* get_bufsize_func);

#ifdef __cplusplus
}
#endif

#endif