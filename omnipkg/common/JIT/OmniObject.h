#pragma once

#include <string>
#include "OmniTypeDefs.h"
#include "OmniAtomicBarrier.h"

typedef struct OmniObject
{
    //Atomic barrier for NRT / RT recompilation of same OmniDef... 
    //This needs a different thinking with supernova, as this should just be locked once per buffer cycle on the RT thread
    AtomicBarrier_t barrier;

    //Path to .omni file
    std::string path;

    //States
    bool compiled;
    bool being_replaced;

    //Infos about object
    std::string name;
    int num_inputs;
    int num_outputs;

    //Init funcs (SC only)
    init_world_func* init_world;
    init_alloc_function_pointers_func* init_alloc_function_pointers;
    
    //Constructor / Perform / Destructor
    Omni_UGenConstructor_func* Omni_UGenConstructor;
    Omni_UGenDestructor_func* Omni_UGenDestructor;
    Omni_UGenPerform_func* Omni_UGenPerform;

} OmniObject