#pragma once

typedef unsigned long size_t; 

typedef struct World World;

//Initialization function for World (SC only)
typedef void init_world_func(void* inWorld);

//Initialization function prototypes for the real time allocator (SC only)
typedef void* RTAlloc_ptr(World *inWorld, size_t in_size);
typedef void* RTRealloc_ptr(World *inWorld, void *in_ptr, size_t in_size);
typedef void  RTFree_ptr(World *inWorld, void *in_ptr);
typedef void  init_alloc_function_pointers_func(RTAlloc_ptr* In_RTAlloc, RTRealloc_ptr* In_RTRealloc, RTFree_ptr* In_RTFree);

//Omni module functions
typedef void* Omni_UGenConstructor_func(float** ins_ptr, int bufsize, double samplerate);
typedef void  Omni_UGenDestructor_func(void* obj_void);
typedef void  Omni_UGenPerform_func(void* ugen_ptr, int buf_size, float** ins_ptr, float** outs_ptr);