#C file to compile together. Should I compile it ahead and use the link pragma on the .o instead?
{.compile: "./RT_Alloc.c".}

#Pass flags to C compiler 
{.passC: "-O3".}

#import ../../omni_print
#const negative_alloc = "WARNING: Trying to allocate a negative value. Allocating 0 bytes.\n"

#Called to init the sc_world* variable in the Nim module
proc init_world*(in_world : pointer) : void {.importc, cdecl.}

#To retrieve world
proc get_sc_world*() : pointer {.importc, cdecl.}

#For debugging
proc print_world*() : void {.importc, cdecl.}

#For testing purposes outside of SuperCollider's RT allocator, every C function is wrapped in another Nim function that
#uses the standard allocation when -d:supercollider is not defined.

#RTAlloc wrapper
proc rt_alloc_SC*(inSize : culong) : pointer {.importc, cdecl.}

#Should only be called from Data and alloc of objects, which already checks for < 0 stuff. So this is faster.
proc omni_alloc*(inSize : culong) : pointer =
    when defined(supercollider):
        return rt_alloc_SC(inSize)
    else:
        return alloc(inSize)

#RTAlloc with 0 memory initialization
proc rt_alloc0_SC*(inSize : culong) : pointer {.importc, cdecl.}

#Should only be called from Data, which already checks for < 0 stuff. So this is faster.
proc omni_alloc0*[N : SomeInteger](inSize : N) : pointer =
    when defined(supercollider):
        return rt_alloc0_SC(inSize)
    else:
        return alloc0(inSize)

#RTRealloc
proc rt_realloc_SC*(inPtr : pointer, inSize : culong) : pointer {.importc, cdecl.}

#Should only be called from Data, which already checks for < 0 stuff. So this is faster.
proc omni_realloc*[N : SomeInteger](inPtr : pointer, inSize : N) : pointer =
    when defined(supercollider):
        return rt_realloc_SC(inPtr, inSize)
    else:
        return realloc(inPtr, inSize)

#RTFree wrapper
proc rt_free_SC*(inPtr : pointer) : void {.importc, cdecl.}

proc omni_free*(inPtr : pointer) : void =
    when defined(supercollider):
        rt_free_SC(inPtr)
    else:
        dealloc(inPtr)