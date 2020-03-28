#include "../../omni.h"

//Global print function. This is set in OmniInitPrint
omni_print_str_val_func_t* omni_print_str_val_func;
omni_print_str_func_t*     omni_print_str_func;
omni_print_float_func_t*   omni_print_float_func;
omni_print_int_func_t*     omni_print_int_func;

void Omni_InitPrint(
    omni_print_str_val_func_t* print_str_val_func, 
    omni_print_str_func_t*     print_str_func, 
    omni_print_float_func_t*   print_float_func, 
    omni_print_int_func_t*     print_int_func
    )
{
    omni_print_str_val_func = print_str_val_func;
    omni_print_str_func     = print_str_func;
    omni_print_float_func   = print_float_func;
    omni_print_int_func     = print_int_func;
}

omni_print_str_val_func_t* get_omni_print_str_val_func()
{
    return omni_print_str_val_func;
}

void omni_print_str_val_C(const char* format_string, size_t value)
{
    omni_print_str_val_func(format_string, value);
}

void omni_print_str_C(const char* format_string)
{
    omni_print_str_func(format_string);
}

void omni_print_float_C(float value)
{
    omni_print_float_func(value);
}

void omni_print_int_C(int value)
{
    omni_print_int_func(value);
}