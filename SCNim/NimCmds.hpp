#pragma once

#include <dlfcn.h>
#include "SC_PlugIn.h"

static InterfaceTable *ft;

//Handle to shared library
void* dl_handle; 

//Initialization functions
typedef void init_world_func(void* inWorld);
init_world_func* init_world;

typedef void print_world_func(void);
print_world_func* print_world;

//Initialization function prototypes for the real time allocator
typedef void* RTAlloc_ptr(World *inWorld, size_t inSize);
typedef void* RTRealloc_ptr(World *inWorld, void *inPtr, size_t inSize);
typedef void  RTFree_ptr(World *inWorld, void *inPtr);
typedef void init_alloc_function_pointers_func(RTAlloc_ptr* In_RTAlloc, RTRealloc_ptr* In_RTRealloc, RTFree_ptr* In_RTFree);
init_alloc_function_pointers_func* init_alloc_function_pointers;

//Nim module functions
typedef void* Nim_UGenConstructor_func(float** ins_SC);
Nim_UGenConstructor_func* Nim_UGenConstructor;

typedef void  Nim_UGenDestructor_func(void* obj_void);
Nim_UGenDestructor_func* Nim_UGenDestructor;

typedef void  Nim_UGenPerform_func(void* ugen_void, int buf_size, float** ins_SC, float** outs_SC);
Nim_UGenPerform_func* Nim_UGenPerform;

bool loadLibSine(World* inWorld, void* cmd)
{
    dl_handle = dlopen("/Users/francescocameli/Library/Application Support/SuperCollider/Extensions/NimCollider/libSine.dylib", RTLD_GLOBAL);

    if(!dl_handle)
    {
        printf("ERROR: Could not load libSine.dylib.\n");
        return true;
    }

    printf("libSine.dylib correctly loaded.\n");

    init_world  = (init_world_func*)dlsym(dl_handle, "init_world");
    print_world = (print_world_func*)dlsym(dl_handle, "print_world");
    
    init_alloc_function_pointers = (init_alloc_function_pointers_func*)dlsym(dl_handle, "init_alloc_function_pointers");

    Nim_UGenConstructor = (Nim_UGenConstructor_func*)dlsym(dl_handle, "UGenConstructor");
    Nim_UGenDestructor  = (Nim_UGenDestructor_func*)dlsym(dl_handle, "UGenDestructor");
    Nim_UGenPerform     = (Nim_UGenPerform_func*)dlsym(dl_handle, "UGenPerform");

    //Initialization routines
    init_world((void*)inWorld);
    init_alloc_function_pointers((RTAlloc_ptr*)ft->fRTAlloc, (RTRealloc_ptr*)ft->fRTRealloc, (RTFree_ptr*)ft->fRTFree);

    print_world();

    //dlclose(dl_handle);

    return true;
}

//needed
void loadLibSine_cleanup(World* inWorld, void* cmd) {}

void NimLoadLibSine(World *inWorld, void* inUserData, struct sc_msg_iter *args, void *replyAddr)
{
    DoAsynchronousCommand(inWorld, replyAddr, nullptr, nullptr, (AsyncStageFn)loadLibSine, 0, 0, loadLibSine_cleanup, 0, nullptr);
}

void DefineNimCmds()
{
    DefinePlugInCmd("/load_libSine", (PlugInCmdFunc)NimLoadLibSine, nullptr);
}