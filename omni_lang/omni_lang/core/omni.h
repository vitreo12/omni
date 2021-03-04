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

#ifndef _OMNI_H_
#define _OMNI_H_

//For platform's size_t and malloc/free (defaults for omni's allocator)
#include "stdlib.h"

//For bool
#include "stdbool.h"

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
    typedef void* omni_alloc_func_t(size_t size);
    typedef void  omni_free_func_t(void *in);
    
    //Print
    typedef void  omni_print_func_t(const char* format_string, ...);

    /****************************/
    /* Initialization functions */
    /****************************/

    //Init global (alloc and print)
    OMNI_DLL_EXPORT extern void Omni_InitGlobal(
        omni_alloc_func_t* alloc_func, 
        omni_free_func_t* free_func, 
        omni_print_func_t* print_func 
    );

    //Init alloc functions only
    OMNI_DLL_EXPORT extern void Omni_InitAlloc(
        omni_alloc_func_t* alloc_func, 
        omni_free_func_t* free_func
    );

    //Init print function only
    OMNI_DLL_EXPORT extern void Omni_InitPrint(omni_print_func_t* print_func);

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
    OMNI_DLL_EXPORT extern void   Omni_UGenSetParam(void* omni_ugen, const char* param, double value);

    //Buffers
    OMNI_DLL_EXPORT extern int    Omni_UGenBuffers();
    OMNI_DLL_EXPORT extern char*  Omni_UGenBuffersNames();
    OMNI_DLL_EXPORT extern char*  Omni_UGenBuffersDefaults();
    OMNI_DLL_EXPORT extern void   Omni_UGenSetBuffer(void* omni_ugen, const char* buffer, const char* value);

    //Outputs
    OMNI_DLL_EXPORT extern int    Omni_UGenOutputs();
    OMNI_DLL_EXPORT extern char*  Omni_UGenOutputsNames();

    /*****************************/
    /* Omni_UGen audio functions */
    /*****************************/

    //Returns a pointer to a new omni_ugen, or NULL if it fails
    OMNI_DLL_EXPORT extern void* Omni_UGenAlloc();
    
    //Return true if it succeeds, or false if it fails
    OMNI_DLL_EXPORT extern bool  Omni_UGenInit(void* omni_ugen, int bufsize, double samplerate, void* buffer_interface);

    //Perform
    OMNI_DLL_EXPORT extern void  Omni_UGenPerform32(void* omni_ugen, float**  ins, float**  outs, int bufsize);
    OMNI_DLL_EXPORT extern void  Omni_UGenPerform64(void* omni_ugen, double** ins, double** outs, int bufsize);

    //Free
    OMNI_DLL_EXPORT extern void  Omni_UGenFree(void* omni_ugen);

#ifdef __cplusplus
}
#endif

#endif
