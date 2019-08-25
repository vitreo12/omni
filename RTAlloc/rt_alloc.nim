#Compile the C file together with Nim's
{.compile: "./RTAlloc.c".}

#The names are the same as the C functions, that's why only importc is used, and not importc : "init_world"

#Called to init the sc_world* variable in the Nim module
proc init_world*(in_world : pointer) : void {.importc.}

#For debugging
proc print_world*() : void {.importc.}

#For testing purposes outside of SuperCollider's RT allocator, every C function is wrapped in another Nim function that
#uses the standard allocation when -d:supercollider is not defined.

#RTAlloc wrapper
proc rt_alloc_C*(inSize : culong) : pointer {.importc: "rt_alloc".}

proc rt_alloc*(inSize : culong) : pointer =
    when defined(supercollider):
        return rt_alloc_C(inSize)
    else:
        return alloc(inSize)

#RTAlloc with 0 memory initialization
proc rt_alloc0_C*(inSize : culong) : pointer {.importc: "rt_alloc0".}

proc rt_alloc0*(inSize : culong) : pointer =
    when defined(supercollider):
        return rt_alloc0_C(inSize)
    else:
        return alloc0(inSize)

#RTRealloc
proc rt_realloc_C*(inPtr : pointer, inSize : culong) : pointer {.importc: "rt_realloc".}

proc rt_realloc*(inPtr : pointer, inSize : culong) : pointer =
    when defined(supercollider):
        return rt_realloc_C(inPtr, inSize)
    else:
        return realloc(inPtr, inSize)

#RTFree wrapper
proc rt_free_C*(inPtr : pointer) : void {.importc: "rt_free".}

proc rt_free*(inPtr : pointer) : void =
    when defined(supercollider):
        rt_free_C(inPtr)
    else:
        dealloc(inPtr)