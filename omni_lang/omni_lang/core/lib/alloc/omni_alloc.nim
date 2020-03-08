#C file to compile together
{.compile: "./omni_alloc.c".}

#Pass optimization flag to C compiler
{.passC: "-O3".}

#Function pointer types
type
    alloc_func_t*   = (proc(inSize : culong) : pointer)
    realloc_func_t* = (proc(inPtr : pointer, inSize : culong) : pointer)
    free_func_t*    = (proc(inPtr : pointer) : void)
    print_func_t*   = (proc(formatString : cstring) : cint)

#Initialization function for allocations
proc Omni_Init*(alloc_func : alloc_func_t, realloc_func : realloc_func_t, free_func : free_func_t) : void {.importc, cdecl.}

############
## ALLOC ###
############

proc omni_alloc_C(inSize : culong)                    : pointer {.importc, cdecl.}
proc omni_alloc0_C(inSize : culong)                   : pointer {.importc, cdecl.}
proc omni_realloc_C(inPtr : pointer, inSize : culong) : pointer {.importc, cdecl.}
proc omni_free_C(inPtr : pointer)                     : void    {.importc, cdecl.}

proc omni_alloc*[N : SomeInteger](inSize : N)  : pointer =
    return omni_alloc_C(inSize)

proc omni_alloc0*[N : SomeInteger](inSize : N) : pointer =
    return omni_alloc0_C(inSize)

proc omni_realloc*[N : SomeInteger](inPtr : pointer, inSize : N) : pointer =
    return omni_realloc_C(inPtr, inSize)

proc omni_free*(inPtr : pointer) : void =
    omni_free_C(inPtr)

############
## PRINT ###
############

proc omni_print*(formatstr: cstring) : cint {.importc, varargs, cdecl.}

#string
proc print*(str : string) : void =
    discard omni_print("%s \n", str)

#int
proc print*[T : SomeInteger](val : T) : void =
    discard omni_print("%d \n", int(val))

#float
proc print*[T : SomeFloat](val : T) : void =
    discard omni_print("%f \n", float(val))