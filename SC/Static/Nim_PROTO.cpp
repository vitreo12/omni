#include <dlfcn.h>
#include <atomic>

#include "SC_PlugIn.h"

#define NAME "Nim_PROTO"

#ifdef __APPLE__
    #define EXTENSION "dylib"
    const char* find_Nim_PROTO_directory_cmd = "i=10; complete_string=$(vmmap -w $serverPID | grep -m 1 'Nim.scx'); file_string=$(awk -v var=\"$i\" '{print $var}' <<< \"$complete_string\"); extra_string=${complete_string%$file_string*}; final_string=${complete_string#\"$extra_string\"}; printf \"%s\" \"${final_string//\"Nim.scx\"/}\"";
#elif __linux__
    #define EXTENSION "so"
    const char* find_Nim_PROTO_directory_cmd = "i=4; complete_string=$(pmap -p $serverPID | grep -m 1 'Nim.so'); file_string=$(awk -v var=\"$i\" '{print $var}' <<< \"$complete_string\"); extra_string=${complete_string%$file_string*}; final_string=${complete_string#\"$extra_string\"}; printf \"%s\" \"${final_string//\"Nim.so\"/}\"";
#endif

//Interface table
static InterfaceTable *ft;

//Use an atomic flag so it works for supernova too
std::atomic_flag has_init_world = ATOMIC_FLAG_INIT;
bool world_init = false;

//Handle to shared library
void* dl_handle; 

//Initialization functions
typedef void init_world_func(void* inWorld);
init_world_func* init_world;

//Initialization function prototypes for the real time allocator
typedef void* RTAlloc_ptr(World *inWorld, size_t inSize);
typedef void* RTRealloc_ptr(World *inWorld, void *inPtr, size_t inSize);
typedef void  RTFree_ptr(World *inWorld, void *inPtr);
typedef void  init_alloc_function_pointers_func(RTAlloc_ptr* In_RTAlloc, RTRealloc_ptr* In_RTRealloc, RTFree_ptr* In_RTFree);
init_alloc_function_pointers_func* init_alloc_function_pointers;

//Nim module functions
typedef void* Nim_UGenConstructor_func(float** ins_SC, int bufsize, double samplerate);
Nim_UGenConstructor_func* Nim_UGenConstructor;

typedef void  Nim_UGenDestructor_func(void* obj_void);
Nim_UGenDestructor_func* Nim_UGenDestructor;

typedef void  Nim_UGenPerform_func(void* ugen_void, int buf_size, float** ins_SC, float** outs_SC);
Nim_UGenPerform_func* Nim_UGenPerform;

//struct
struct Nim_PROTO : public Unit 
{
    void* Nim_obj;
};

//DSP functions
static void Nim_next(Nim_PROTO* unit, int inNumSamples);
static void Nim_Ctor(Nim_PROTO* unit);
static void Nim_Dtor(Nim_PROTO* unit);

void Nim_Ctor(Nim_PROTO* unit) 
{
    //Initialization routines for the Nim UGen. 
    if(!world_init)
    {
        //Acquire lock
        while has_init_world.test_and_set(std::memory_order_acquire)
            ; //spin

        //First thread that reaches this will set it for all
        if(!world_init)
        {
            if(!init_world || !init_alloc_function_pointers)
                Print("ERROR: No %s.%s loaded\n", NAME, EXTENSION);
            else 
            {
                init_world((void*)unit->mWorld);
                init_alloc_function_pointers((RTAlloc_ptr*)ft->fRTAlloc, (RTRealloc_ptr*)ft->fRTRealloc, (RTFree_ptr*)ft->fRTFree);
            }

            //Still init. Things won't change up until next server reboot.
            world_init = true;
        }

        //Release lock
        has_init_world.clear(std::memory_order_release); 
    }

    if(Nim_UGenConstructor && init_world && init_alloc_function_pointers)
        unit->Nim_obj = (void*)Nim_UGenConstructor(unit->mInBuf);
    else
    {
        Print("ERROR: No %s.%s loaded\n", NAME, EXTENSION);
        unit->Nim_obj = nullptr;
    }
        
    SETCALC(Nim_next);
    
    Nim_next(unit, 1);
}

void Nim_Dtor(Nim_PROTO* unit) 
{
    if(unit->Nim_obj)
        Nim_UGenDestructor(unit->Nim_obj);
}

void Nim_next(Nim_PROTO* unit, int inNumSamples) 
{
    if(unit->Nim_obj)
        Nim_UGenPerform(unit->Nim_obj, inNumSamples, unit->mInBuf, unit->mOutBuf);
    else
    {
        for(int i = 0; i < unit->mNumOutputs; i++)
        {
            for(int y = 0; y < inNumSamples; y++)
                unit->mOutBuf[i][y] = 0.0f;
        }
    }
}

//Single thread call at server boot
bool Nim_load()
{
    std::string final_path;

    #ifdef __APPLE__
        final_path = NimCollider_folder_path + "libSine.dylib";
        
        if(!file_exists(final_path))
        {
            printf("ERROR: %s doesn't exist \n", final_path.c_str());
            return false;
        }

        dl_handle = dlopen(final_path.c_str(), RTLD_GLOBAL);
    #elif __linux__
        final_path = NimCollider_folder_path + "libSine.so";

        if(!file_exists(final_path))
        {
            printf("ERROR: %s doesn't exist \n", final_path.c_str());
            return false;
        }

        dl_handle = dlopen(final_path.c_str(), RTLD_NOW | RTLD_DEEPBIND | RTLD_GLOBAL);
    #endif

    if(!dl_handle)
    {
        printf("ERROR: Could not load %s.%s. \n", NAME, EXTENSION);
        return false;
    }

    printf("*** %s.%s correctly loaded.\n", NAME, EXTENSION);

    init_world  = (init_world_func*)dlsym(dl_handle, "init_world");
    if(!init_world)
    {
        printf("ERROR: %s.%s. Could not load init_world function.\n", NAME, EXTENSION);
        return false;
    }
    
    init_alloc_function_pointers = (init_alloc_function_pointers_func*)dlsym(dl_handle, "init_alloc_function_pointers");
    if(!init_alloc_function_pointers)
    {
        printf("ERROR: %s.%s. Could not load init_alloc_function_pointers function.\n", NAME, EXTENSION);
        return false;
    }

    Nim_UGenConstructor = (Nim_UGenConstructor_func*)dlsym(dl_handle, "UGenConstructor");
    if(!Nim_UGenConstructor)
    {
        printf("ERROR: %s.%s. Could not load Nim_UGenConstructor function.\n", NAME, EXTENSION);
        return false;
    }

    Nim_UGenDestructor  = (Nim_UGenDestructor_func*)dlsym(dl_handle, "UGenDestructor");
    if(!Nim_UGenDestructor)
    {
        printf("ERROR: %s.%s. Could not load Nim_UGenDestructor function.\n", NAME, EXTENSION);
        return false;
    }

    Nim_UGenPerform     = (Nim_UGenPerform_func*)dlsym(dl_handle, "UGenPerform");
    if(!Nim_UGenPerform)
    {
        printf("ERROR: %s.%s. Could not load Nim_UGenPerform function.\n", NAME, EXTENSION);
        return false;
    }

    //print_world();

    //dlclose(dl_handle);

    return true;
}

//Single thread call at server quit
void Nim_unload()
{
    if(dl_handle)
    {
        dlclose(dl_handle);
        printf("%s.%s unloaded \n", NAME, EXTENSION);
    }
}

//Rename Nim_PROTO to the name of the nim file to compile
PluginLoad(Nim_PROTOUGens) 
{
    ft = inTable; 

    Nim_load();

    DefineDtorUnit(Nim_PROTO);
}

/* Register an unload function on server quit. */
C_LINKAGE SC_API_EXPORT void unload(InterfaceTable *inTable)
{
    Nim_unload();
}