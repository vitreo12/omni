#C file to compile together
{.compile: "./omni_alloc.c".}

#Pass optimization flag to C compiler
{.passC: "-O3".}

#C funcs
proc omni_alloc_C*(inSize : culong)                    : pointer {.importc: "omni_alloc_C", cdecl.}
proc omni_realloc_C*(inPtr : pointer, inSize : culong) : pointer {.importc: "omni_realloc_C", cdecl.}
proc omni_free_C*(inPtr : pointer)                     : void    {.importc: "omni_free_C", cdecl.}

#Wrappers around the C functions
proc omni_alloc*[N : SomeInteger](inSize : N)  : pointer {.inline.} =
    return omni_alloc_C(inSize)

proc omni_alloc0*[N : SomeInteger](inSize : N) : pointer {.inline.} =
    let mem = omni_alloc_C(inSize)
    if not isNil(mem):
        zeroMem(mem, inSize)
    return mem

proc omni_realloc*[N : SomeInteger](inPtr : pointer, inSize : N) : pointer {.inline.} =
    return omni_realloc_C(inPtr, inSize)

proc omni_free*(inPtr : pointer) : void {.inline.} =
    omni_free_C(inPtr)