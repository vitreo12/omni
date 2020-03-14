#include "../../omni.h"

//Global print function. This is set in OmniIniPrint
omni_print_func_t* omni_print_func; // = printf; //Default it with printf

void Omni_InitPrint(omni_print_func_t* print_func)
{
    omni_print_func = print_func;
}

omni_print_func_t* get_omni_print_func()
{
    return omni_print_func;
}

void omni_print_C(const char* format_string, ...)
{
    omni_print_func(format_string);
}