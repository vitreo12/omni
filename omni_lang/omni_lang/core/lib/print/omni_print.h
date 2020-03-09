#ifndef _OMNI_PRINT_
#define _OMNI_PRINT_

typedef void print_func_t(const char* formatString, ...);
print_func_t* omni_print_func; // = printf; //Default it with printf

#endif