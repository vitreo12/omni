#C file to compile together
{.compile: "./omni_global_init.c".}

#Pass optimization flag to C compiler
{.passC: "-O3".}

#[ 
import ../alloc/omni_alloc
import ../print/omni_print
import ../utilities/omni_utilities

#Initialization function for everything
proc OmniInitGlobal*(alloc_func : alloc_func_t, realloc_func : realloc_func_t, free_func : free_func_t, print_func : print_func_t, get_samplerate_func : get_samplerate_func_t, get_bufsize_func : get_bufsize_func_t) : void {.exportc: "OmniInitGlobal", cdecl.} =
    #Alloc
    OmniInitAlloc(alloc_func, realloc_func, free_func)
    
    #Print
    OmniInitPrint(print_func)

    #Samplerate/Bufsize
    OmniInitGetSamplerateGetBufsize(get_samplerate_func, get_bufsize_func)

    print("Called OmniInitGlobal")
]#