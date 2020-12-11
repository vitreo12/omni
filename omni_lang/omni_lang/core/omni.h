// MIT License
// 
// Copyright (c) 2020 Francesco Cameli
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

#ifndef _OMNI_H_
#define _OMNI_H_

//For platform's size_t and malloc/realloc/free (defaults for omni's allocator)
#include "stdlib.h"

//Needed for .dll export
#ifdef _WIN32
    #define OMNI_DLL_EXPORT __declspec(dllexport)
#else
    #define OMNI_DLL_EXPORT __attribute__ ((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

    /**************************************/
    /* Initialization function prototypes */
    /**************************************/
    
    //Alloc
    typedef void*  omni_alloc_func_t(size_t in_size);
    typedef void*  omni_realloc_func_t(void *in, size_t in_size);
    typedef void   omni_free_func_t(void *in);
    
    //Print
    typedef void   omni_print_debug_func_t(const char* format_string, size_t value);
    typedef void   omni_print_str_func_t(const char* format_string);
    typedef void   omni_print_float_func_t(float value);
    typedef void   omni_print_int_func_t(int value);

    //Utilities
    //typedef double omni_get_samplerate_func_t();
    //typedef int    omni_get_bufsize_func_t();

    /****************************/
    /* Initialization functions */
    /****************************/

    //Global (initialize alloc, print, utilities in one place)
    OMNI_DLL_EXPORT extern void Omni_InitGlobal(
        omni_alloc_func_t* alloc_func, 
        omni_realloc_func_t* realloc_func, 
        omni_free_func_t* free_func, 
        omni_print_debug_func_t* print_debug_func, 
        omni_print_str_func_t* print_str_func, 
        omni_print_float_func_t* print_float_func, 
        omni_print_int_func_t* print_int_func
        //omni_get_samplerate_func_t* get_samplerate_func, 
        //omni_get_bufsize_func_t* get_bufsize_func
    );

    //Alloc
    OMNI_DLL_EXPORT extern void Omni_InitAlloc(omni_alloc_func_t* alloc_func, omni_realloc_func_t* realloc_func, omni_free_func_t* free_func);

    //Print
    OMNI_DLL_EXPORT extern void Omni_InitPrint(omni_print_debug_func_t* print_debug_func, omni_print_str_func_t* print_str_func, omni_print_float_func_t* print_float_func, omni_print_int_func_t* print_int_func);
    OMNI_DLL_EXPORT extern omni_print_debug_func_t* get_omni_print_debug_func();

    //Utilities
    //OMNI_DLL_EXPORT extern void Omni_InitGetSamplerateGetBufsize(omni_get_samplerate_func_t* get_samplerate_func, omni_get_bufsize_func_t* get_bufsize_func);

    /***************************/
    /* Omni_UGen I/O functions */
    /***************************/

    //Inputs
    OMNI_DLL_EXPORT extern int    Omni_UGenInputs();
    OMNI_DLL_EXPORT extern char*  Omni_UGenInputsNames();
    OMNI_DLL_EXPORT extern float* Omni_UGenInputsDefaults();

    //Params
    OMNI_DLL_EXPORT extern int    Omni_UGenParams();
    OMNI_DLL_EXPORT extern char*  Omni_UGenParamsNames();
    OMNI_DLL_EXPORT extern float* Omni_UGenParamsDefaults();

    //Buffers
    OMNI_DLL_EXPORT extern int    Omni_UGenBuffers();
    OMNI_DLL_EXPORT extern char*  Omni_UGenBuffersNames();
    OMNI_DLL_EXPORT extern char*  Omni_UGenBuffersDefaults();

    //Outputs
    OMNI_DLL_EXPORT extern int    Omni_UGenOutputs();
    OMNI_DLL_EXPORT extern char*  Omni_UGenOutputsNames();

    /*****************************/
    /* Omni_UGen audio functions */
    /*****************************/

    //Alloc/Init. Returns NULL if fails to alloc/init
    OMNI_DLL_EXPORT extern void*  Omni_UGenAllocInit32(float**  ins, int bufsize, double samplerate, void* buffer_interface);
    OMNI_DLL_EXPORT extern void*  Omni_UGenAllocInit64(double** ins, int bufsize, double samplerate, void* buffer_interface);
    
    //returns NULL if it fails
    OMNI_DLL_EXPORT extern void*  Omni_UGenAlloc();
    
    //Return 1 if it succeeds / 0 if it fails
    OMNI_DLL_EXPORT extern int    Omni_UGenInit32(void* omni_ugen, float**  ins, int bufsize, double samplerate, void* buffer_interface);
    OMNI_DLL_EXPORT extern int    Omni_UGenInit64(void* omni_ugen, double** ins, int bufsize, double samplerate, void* buffer_interface);

    //Perform
    OMNI_DLL_EXPORT extern void   Omni_UGenPerform32(void* omni_ugen, float**  ins, float**  outs, int bufsize);
    OMNI_DLL_EXPORT extern void   Omni_UGenPerform64(void* omni_ugen, double** ins, double** outs, int bufsize);

    //Free
    OMNI_DLL_EXPORT extern void   Omni_UGenFree(void* omni_ugen);

#ifdef __cplusplus
}
#endif

#endif