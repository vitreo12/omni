#ifndef _OMNI_PRINT_
#define _OMNI_PRINT_

#ifdef __cplusplus
extern "C" {
#endif

typedef void print_func_t(const char* formatString, ...);
//extern print_func_t* omni_print_func;

extern void OmniInitPrint(print_func_t* print_func);

extern print_func_t* get_omni_print_func();

#ifdef __cplusplus
}
#endif

#endif