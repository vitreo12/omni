#ifndef _OMNI_ALLOC_
#define _OMNI_ALLOC_

typedef unsigned long size_t; 

typedef void* alloc_func_t(size_t inSize);
alloc_func_t* omni_alloc_func; // = malloc; //Default with malloc

typedef void* realloc_func_t(void *inPtr, size_t inSize);
realloc_func_t* omni_realloc_func; // = realloc; //Default with realloc

typedef void  free_func_t(void *inPtr);
free_func_t* omni_free_func; // = free; //Default it with free

#endif