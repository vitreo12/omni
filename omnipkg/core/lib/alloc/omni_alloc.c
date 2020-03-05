typedef unsigned long size_t; 

typedef void* alloc_func_t(size_t inSize);
alloc_func_t* omni_alloc_func;

typedef void* realloc_func_t(void *inPtr, size_t inSize);
realloc_func_t* omni_realloc_func;

typedef void  free_func_t(void *inPtr);
free_func_t* omni_free_func;

void Omni_Init_Alloc(alloc_func_t* alloc_func, realloc_func_t* realloc_func, free_func_t* free_func)
{
    omni_alloc_func   = alloc_func;
    omni_realloc_func = realloc_func;
    omni_free_func    = free_func;
}

void* omni_alloc_C(size_t inSize)
{
    return omni_alloc_func(inSize);
}

void* omni_alloc0_C(size_t inSize)
{
    void* memory = omni_alloc_func(inSize);
    if(memory)
        memset(memory, 0, inSize);
    return memory;
}

void* omni_realloc_C(void *inPtr, size_t inSize)
{
    return omni_realloc_func(inPtr, inSize);
}

void omni_free_C(void* inPtr)
{
    omni_free_func(inPtr);
}