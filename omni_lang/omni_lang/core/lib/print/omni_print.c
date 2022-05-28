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

#define OMNI_STR_SIZE 256

//Global print function. Defaulted to printf if not defined
omni_print_func_t* omni_print_func = (omni_print_func_t*)printf;

OMNI_DLL_EXPORT void Omni_InitPrint(omni_print_func_t* print_func)
{
    if(!print_func)
    {
        printf("ERROR: Omni_InitPrint: 'print_func' is NULL. Reverting to 'printf'.\n");
        omni_print_func = (omni_print_func_t*)printf;
        return;
    }
    
    omni_print_func = print_func;
}

OMNI_DLL_EXPORT void omni_print_C(const char* format_string, ...)
{
    omni_print_func(format_string);
}

OMNI_DLL_EXPORT void omni_print_str_C(const char* value)
{
    char result[OMNI_STR_SIZE];
    snprintf(result, sizeof(result), "%s\n", value);
    omni_print_func(result);
}

OMNI_DLL_EXPORT void omni_print_float_C(float value)
{ 
    //Make sure to run conversions here, as the omni_print_func provided might not be 
    //suitable for %f conversion (as it is for omnicollider's, for example)
    char result[OMNI_STR_SIZE];
    snprintf(result, sizeof(result), "%f\n", value);
    omni_print_func(result);
}

OMNI_DLL_EXPORT void omni_print_int_C(int value)
{
    //Make sure to run conversions here, as the omni_print_func provided might not be 
    //suitable for %d conversion (as it is for omnicollider's, for example)
    char result[OMNI_STR_SIZE];
    snprintf(result, sizeof(result), "%d\n", value);
    omni_print_func(result);
}

OMNI_DLL_EXPORT void omni_print_label_float_C(const char* label, float value)
{ 
    //Make sure to run conversions here, as the omni_print_func provided might not be 
    //suitable for %f conversion (as it is for omnicollider's, for example)
    char result[OMNI_STR_SIZE];
    snprintf(result, sizeof(result), "%s: %f\n", label, value);
    omni_print_func(result);
}

OMNI_DLL_EXPORT void omni_print_label_int_C(const char* label, int value)
{ 
    //Make sure to run conversions here, as the omni_print_func provided might not be 
    //suitable for %f conversion (as it is for omnicollider's, for example)
    char result[OMNI_STR_SIZE];
    snprintf(result, sizeof(result), "%s: %d\n", label, value);
    omni_print_func(result);
}

OMNI_DLL_EXPORT void omni_print_compose_int_C(const char* label, int value, const char* post)
{
    //Make sure to run conversions here, as the omni_print_func provided might not be 
    //suitable for %d conversion (as it is for omnicollider's, for example)
    char result[OMNI_STR_SIZE];
    snprintf(result, sizeof(result), "%s%d%s\n", label, value, post);
    omni_print_func(result);
}

OMNI_DLL_EXPORT void omni_print_bool_C(int value)
{
    if(value == 0)
        omni_print_func("false\n");
    else
        omni_print_func("true\n");
}
