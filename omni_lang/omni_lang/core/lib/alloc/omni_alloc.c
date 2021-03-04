// MIT License
// 
// Copyright (c) 2020-2021 Francesco Cameli
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include "../../omni.h"

//Reset
#define omni_reset_alloc_funcs() \
    omni_alloc_func    = (omni_alloc_func_t*)malloc; \
    omni_realloc_func  = (omni_realloc_func_t*)realloc; \
    omni_free_func     = (omni_free_func_t*)free;     

//Global allocation functions. These are set in Omni_InitAlloc, or defaulted to malloc / realloc / free
omni_alloc_func_t*   omni_alloc_func    = (omni_alloc_func_t*)malloc;
omni_realloc_func_t* omni_realloc_func  = (omni_realloc_func_t*)realloc;
omni_free_func_t*    omni_free_func     = (omni_free_func_t*)free;    

//To print error
extern omni_print_func_t* omni_print_func;

//Provide custom alloc/realloc/free
OMNI_DLL_EXPORT void Omni_InitAlloc(omni_alloc_func_t* alloc_func, omni_realloc_func_t* realloc_func, omni_free_func_t* free_func)
{
    if(!alloc_func)
    {
        omni_print_func("ERROR: Omni_InitAlloc: null 'alloc_func'. Reverting to 'malloc' / 'realloc' / 'free'.\n");
        omni_reset_alloc_funcs();
        return;
    }
    else if(!realloc_func)
    {
        omni_print_func("ERROR: Omni_InitAlloc: null 'realloc_func'. Reverting to 'malloc' / 'realloc' / 'free'.\n");
        omni_reset_alloc_funcs();
        return;
    }
    else if(!free_func)
    {
        omni_print_func("ERROR: Omni_InitAlloc: null 'free_func'. Reverting to 'malloc' / realloc / free.\n");
        omni_reset_alloc_funcs();
        return;
    }
    
    omni_alloc_func   = alloc_func;
    omni_realloc_func = realloc_func;
    omni_free_func    = free_func;
}

OMNI_DLL_EXPORT void* omni_alloc_C(size_t size)
{
    return omni_alloc_func(size);
}

OMNI_DLL_EXPORT void* omni_realloc_C(void *in_ptr, size_t size)
{
    return omni_realloc_func(in_ptr, size);
}

OMNI_DLL_EXPORT void omni_free_C(void* in_ptr)
{
    omni_free_func(in_ptr);
}
