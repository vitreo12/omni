#ifndef _OMNI_PRINT_
#define _OMNI_PRINT_

typedef int print_func_t(const char* formatString, ...);
print_func_t* omni_print_func; // = printf; //Default it with printf

#endif