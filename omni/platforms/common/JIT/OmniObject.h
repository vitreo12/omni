#pragma once

#include <string>
#include "OmniTypeDefs.h"

typedef struct OmniObject
{
    //Path to .omni file
    std::string path;

    //States
    bool compiled; //Should be atomic for supernova
    bool being_replaced; //Should be atomic for supernova

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