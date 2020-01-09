#pragma once

typedef unsigned long size_t; 

typedef struct World World;

//Initialization functions
typedef void init_world_func(void* inWorld);
init_world_func* init_world;

//Initialization function prototypes for the real time allocator
typedef void* RTAlloc_ptr(World *inWorld, size_t inSize);
typedef void* RTRealloc_ptr(World *inWorld, void *inPtr, size_t inSize);
typedef void  RTFree_ptr(World *inWorld, void *inPtr);
typedef void init_alloc_function_pointers_func(RTAlloc_ptr* In_RTAlloc, RTRealloc_ptr* In_RTRealloc, RTFree_ptr* In_RTFree);
init_alloc_function_pointers_func* init_alloc_function_pointers;

//Omni module functions
typedef void* Omni_UGenConstructor_func(float** ins_SC, int bufsize, double samplerate);
Omni_UGenConstructor_func* Omni_UGenConstructor;

typedef void  Omni_UGenDestructor_func(void* obj_void);
Omni_UGenDestructor_func* Omni_UGenDestructor;

typedef void  Omni_UGenPerform_func(void* ugen_void, int buf_size, float** ins_SC, float** outs_SC);
Omni_UGenPerform_func* Omni_UGenPerform;