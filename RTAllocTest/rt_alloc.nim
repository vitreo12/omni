#Compile the C file together with Nim's
{.compile: "./RTAllocTest.c".}

#The names are the same as the C functions, that's why only importc is used, and not importc : "init_world"

#Called to init the sc_world* variable in the Nim module
proc init_world*(in_world : pointer) : void {.importc.}

#For debugging
proc print_world*() : void {.importc.}

#RTAlloc wrapper
proc rt_alloc*(in_size : culong) : pointer {.importc.}

#RTAlloc with 0 memory initialization
proc rt_alloc0*(in_size : culong) : pointer {.importc.}

#RTRealloc
proc rt_realloc*(in_ptr : pointer, in_size : culong) : pointer {.importc.}

#RTFree wrapper
proc rt_free*(in_ptr : pointer) : void {.importc.}