#Compile the C file together with Nim's
{.compile: "./RTAllocTest.c".}

#The names are the same as the C functions, that's why only importc is used, and not importc : "init_world"

#Called to init the sc_world* variable in the Nim module
proc init_world*(in_world : pointer) : void {.importc.}

#For debugging
proc print_world*() : void {.importc.}

#For testing purposes outside of SuperCollider's RT allocator, every C function is wrapped in another Nim function that
#uses the standard allocation when -d:supercollider is not defined.

#RTAlloc wrapper
proc rt_alloc_C*(in_size : culong) : pointer {.importc: "rt_alloc".}

proc rt_alloc*(in_size : culong) : pointer =
    when defined(supercollider):
        return rt_alloc_C(in_size)
    else:
        return alloc(in_size)

#RTAlloc with 0 memory initialization
proc rt_alloc0_C*(in_size : culong) : pointer {.importc: "rt_alloc0".}

proc rt_alloc0*(in_size : culong) : pointer =
    when defined(supercollider):
        return rt_alloc0_C(in_size)
    else:
        return alloc0(in_size)

#RTRealloc
proc rt_realloc_C*(in_ptr : pointer, in_size : culong) : pointer {.importc: "rt_realloc".}

proc rt_realloc*(in_ptr : pointer, in_size : culong) : pointer =
    when defined(supercollider):
        return rt_realloc_C(in_ptr, in_size)
    else:
        return realloc(in_ptr, in_size)

#RTFree wrapper
proc rt_free_C*(in_ptr : pointer) : void {.importc: "rt_free".}

proc rt_free*(in_ptr : pointer) : void =
    when defined(supercollider):
        rt_free_C(in_ptr)
    else:
        dealloc(in_ptr)