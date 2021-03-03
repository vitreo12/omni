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
#include <stdio.h>

//Global print function. Defaulted to printf if not defined
omni_print_func_t* omni_print_func = (omni_print_func_t*)printf;

OMNI_DLL_EXPORT void Omni_InitPrint(omni_print_func_t* print_func)
{
    omni_print_func = print_func;
}

OMNI_DLL_EXPORT void omni_print_C(const char* string, ...)
{
    omni_print_func(string);
}

OMNI_DLL_EXPORT void omni_print_str_C(const char* value)
{
    omni_print_func("%s\n", value);
}

OMNI_DLL_EXPORT void omni_print_float_C(float value)
{ 
    //Make sure to run conversions here, as the omni_print_func provided might not be 
    //suitable for %f conversion (as it is for omnicollider's, for example)
    char char_value[16];
    snprintf(char_value, sizeof(char_value), "%f", value);
    omni_print_func("%s\n", char_value);
}

OMNI_DLL_EXPORT void omni_print_int_C(int value)
{
    //Make sure to run conversions here, as the omni_print_func provided might not be 
    //suitable for %d conversion (as it is for omnicollider's, for example)
    char char_value[16];
    snprintf(char_value, sizeof(char_value), "%d", value);
    omni_print_func("%s\n", char_value);
}
