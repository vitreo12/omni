#ifndef _OMNI_ALLOC_
#define _OMNI_ALLOC_

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned long size_t; 

typedef void* alloc_func_t(size_t inSize);
//extern alloc_func_t* omni_alloc_func;

typedef void* realloc_func_t(void *inPtr, size_t inSize);
//extern realloc_func_t* omni_realloc_func;

typedef void  free_func_t(void *inPtr);
//extern free_func_t* omni_free_func;

extern void Omni_InitAlloc(alloc_func_t* alloc_func, realloc_func_t* realloc_func, free_func_t* free_func);

#ifdef __cplusplus
}
#endif

#endif