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

#include "../../omni.h"
#include "stdio.h"

//Global print functions. These are set in OmniInitPrint, or defaulted to prinf if not defined
omni_print_debug_func_t*   omni_print_debug_func = NULL;
omni_print_str_func_t*     omni_print_str_func   = NULL;
omni_print_float_func_t*   omni_print_float_func = NULL;
omni_print_int_func_t*     omni_print_int_func   = NULL;

OMNI_DLL_EXPORT void Omni_InitPrint(
    omni_print_debug_func_t*   print_debug_func, 
    omni_print_str_func_t*     print_str_func, 
    omni_print_float_func_t*   print_float_func, 
    omni_print_int_func_t*     print_int_func
    )
{
    omni_print_debug_func   = print_debug_func;
    omni_print_str_func     = print_str_func;
    omni_print_float_func   = print_float_func;
    omni_print_int_func     = print_int_func;
}

OMNI_DLL_EXPORT omni_print_debug_func_t* get_omni_print_debug_func()
{
    return omni_print_debug_func;
}

OMNI_DLL_EXPORT void omni_print_debug_C(const char* format_string, size_t value)
{
    if(omni_print_debug_func)
        omni_print_debug_func(format_string, value);
    else
        printf("%s%lu\n", format_string, value);
}

OMNI_DLL_EXPORT void omni_print_str_C(const char* format_string)
{
    if(omni_print_str_func)
        omni_print_str_func(format_string);
    else
        printf("%s\n", format_string);
}

OMNI_DLL_EXPORT void omni_print_float_C(float value)
{
    if(omni_print_float_func)
        omni_print_float_func(value);
    else
        printf("%f\n", value);
}

OMNI_DLL_EXPORT void omni_print_int_C(int value)
{
    if(omni_print_int_func)
        omni_print_int_func(value);
    else
        printf("%d\n", value);
}