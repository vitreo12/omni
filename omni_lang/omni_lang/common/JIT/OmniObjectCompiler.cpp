#include "OmniObjectCompiler.h"

bool OmniObjectCompiler::compile_omni_object(const char* omni_file_path)
{
    return true;
}   

bool OmniObjectCompiler::unload_omni_object(OmniObject* omni_object)
{
    return true;
}

void OmniObjectCompiler::init_omni_object(OmniObject* omni_object)
{
    omni_object->barrier.state.store(false);

    if(!omni_object->path.empty()) //If not empty, clear content.
        omni_object->path.clear();
    
    omni_object->compiled = false;
    omni_object->being_replaced = false;

    if(!omni_object->name.empty()) //If not empty, clear content.
        omni_object->name.clear();

    omni_object->num_inputs = -1;
    omni_object->num_outputs = -1;

    //Init funcs (SC only)
    omni_object->init_world = nullptr;
    omni_object->init_alloc_function_pointers = nullptr;
    
    //Constructor / Perform / Destructor
    omni_object->Omni_UGenConstructor = nullptr;
    omni_object->Omni_UGenDestructor = nullptr;
    omni_object->Omni_UGenPerform = nullptr;
}