var OMNI_PROTO_CPP = """

#include <atomic>

#include "SC_PlugIn.h"

#define NAME "Omni_PROTO"

#ifdef __APPLE__
    #define EXTENSION "dylib"
#elif __linux__
    #define EXTENSION "so"
#elif _WIN32
    #define EXTENSION "dll"
#endif

//Interface table
static InterfaceTable *ft;

//Use an atomic flag so it works for supernova too
std::atomic_flag has_init_world = ATOMIC_FLAG_INIT;
bool world_init = false;

//Initialization functions. Wrapped in C since the Nim lib is exported with C named libraries
extern "C" 
{
    //Initialization of World
    extern void init_world(void* inWorld);

    //Initialization function prototypes for the real time allocator
    typedef void* RTAlloc_ptr(World *inWorld, size_t inSize);
    typedef void* RTRealloc_ptr(World *inWorld, void *inPtr, size_t inSize);
    typedef void  RTFree_ptr(World *inWorld, void *inPtr);
    extern void   init_alloc_function_pointers(RTAlloc_ptr* In_RTAlloc, RTRealloc_ptr* In_RTRealloc, RTFree_ptr* In_RTFree);

    //Nim module functions
    extern void* UGenConstructor(float** ins_SC, int bufsize, double samplerate);
    extern void  UGenDestructor(void* obj_void);
    extern void  UGenPerform(void* ugen_void, int buf_size, float** ins_SC, float** outs_SC);
}

//struct
struct Omni_PROTO : public Unit 
{
    void* Nim_obj;
};

//DSP functions
static void Omni_PROTO_next(Omni_PROTO* unit, int inNumSamples);
static void Omni_PROTO_Ctor(Omni_PROTO* unit);
static void Omni_PROTO_Dtor(Omni_PROTO* unit);

void Omni_PROTO_Ctor(Omni_PROTO* unit) 
{
    //Initialization routines for the Nim UGen. 
    if(!world_init)
    {
        //Acquire lock
        while(has_init_world.test_and_set(std::memory_order_acquire))
            ; //spin

        //First thread that reaches this will set it for all
        if(!world_init)
        {
            if(!(&init_world) || !(&init_alloc_function_pointers))
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

    if(&UGenConstructor && &init_world && &init_alloc_function_pointers)
        unit->Nim_obj = (void*)UGenConstructor(unit->mInBuf, unit->mWorld->mBufLength, unit->mWorld->mSampleRate);
    else
    {
        Print("ERROR: No %s.%s loaded\n", NAME, EXTENSION);
        unit->Nim_obj = nullptr;
    }
        
    SETCALC(Omni_PROTO_next);
    
    Omni_PROTO_next(unit, 1);
}

void Omni_PROTO_Dtor(Omni_PROTO* unit) 
{
    if(unit->Nim_obj)
        UGenDestructor(unit->Nim_obj);
}

void Omni_PROTO_next(Omni_PROTO* unit, int inNumSamples) 
{
    if(unit->Nim_obj)
        UGenPerform(unit->Nim_obj, inNumSamples, unit->mInBuf, unit->mOutBuf);
    else
    {
        for(int i = 0; i < unit->mNumOutputs; i++)
        {
            for(int y = 0; y < inNumSamples; y++)
                unit->mOutBuf[i][y] = 0.0f;
        }
    }
}

//Rename Omni_PROTO to the name of the nim file to compile
PluginLoad(Omni_PROTOUGens) 
{
    ft = inTable; 

    DefineDtorUnit(Omni_PROTO);
}

"""