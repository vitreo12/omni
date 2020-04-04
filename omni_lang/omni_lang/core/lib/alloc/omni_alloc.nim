#C file to compile together
{.compile: "./omni_alloc.c".}

#Pass optimization flag to C compiler
{.passC: "-O3".}

#C funcs
proc omni_alloc_C*(in_size : culong)                     : pointer {.importc: "omni_alloc_C", cdecl.}
proc omni_realloc_C*(in_ptr : pointer, in_size : culong) : pointer {.importc: "omni_realloc_C", cdecl.}
proc omni_free_C*(in_ptr : pointer)                      : void    {.importc: "omni_free_C", cdecl.}

#Wrappers around the C functions
proc omni_alloc*[N : SomeInteger](in_size : N)  : pointer {.inline.} =
    return omni_alloc_C(in_size)

proc omni_alloc0*[N : SomeInteger](in_size : N) : pointer {.inline.} =
    let mem = omni_alloc_C(in_size)
    if not isNil(mem):
        zeroMem(mem, in_size)
    return mem

proc omni_realloc*[N : SomeInteger](in_ptr : pointer, in_size : N) : pointer {.inline.} =
    return omni_realloc_C(in_ptr, in_size)

proc omni_free*(in_ptr : pointer) : void {.inline.} =
    omni_free_C(in_ptr)


# ===================================================== #
# Discard the use of alloc / alloc0 / realloc / dealloc #
# ===================================================== #

from macros import error

proc alloc*[N : SomeInteger](in_size : N) : void =
    static:
        error("alloc is not supported. Use Data to allocate memory.")

proc alloc0*[N : SomeInteger](in_size : N) : void =
    static:
        error("alloc0 is not supported. Use Data to allocate memory.")

proc realloc*[N : SomeInteger](in_ptr : pointer, in_size : N) : void =
    static:
        error("realloc is not supported. Use Data to allocate memory.")

#Don't know why this doesn't work...
#[ proc dealloc*(in_ptr : pointer) : void =
    static:
        error("dealloc is not supported") ]#