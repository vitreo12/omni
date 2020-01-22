#pragma once

#include "SC_PlugIn.h"
#include "GlobalVariables.h"

bool CompileFile(World* inWorld, void* cmd)
{
    return true;
}

void CompileFileCleanup(World* inWorld, void* cmd) {}

void OmniCompileFile(World *inWorld, void* inUserData, struct sc_msg_iter *args, void *replyAddr)
{
    DoAsynchronousCommand(inWorld, replyAddr, nullptr, nullptr, (AsyncStageFn)CompileFile, 0, 0, CompileFileCleanup, 0, nullptr);
}

void DefineOmniCmds()
{
    DefinePlugInCmd("/omni_compile_file", (PlugInCmdFunc)OmniCompileFile, nullptr);
    
    //To be added:
    DefinePlugInCmd("/omni_free_def", nullptr, nullptr);
    DefinePlugInCmd("/omni_get_objects_list", nullptr, nullptr);
    DefinePlugInCmd("/omni_get_object_by_name", nullptr, nullptr);
}


/*************************/
/* Init / Quit functions */
/*************************/

//Allocate global variables needed for runtime
void omni_boot()
{
    omni_objects_array = new OmniObjectsArray_SC;
    omni_utilities = new OmniUtilities_SC;
}

//Deallocate global variables
void omni_quit()
{
    printf("***Quitting omni...\n");
    
    delete omni_objects_array;
    delete omni_utilities;
}

/*
bool loadFile(World* inWorld, void* cmd)
{
    std::string final_path;

    #ifdef __APPLE__     
        if(!file_exists(final_path))
        {
            printf("ERROR: %s doesn't exist \n", final_path.c_str());
            return true;
        }

        dl_handle = dlopen(final_path.c_str(), RTLD_GLOBAL);
    #elif __linux__
        if(!file_exists(final_path))
        {
            printf("ERROR: %s doesn't exist \n", final_path.c_str());
            return true;
        }

        dl_handle = dlopen(final_path.c_str(), RTLD_NOW | RTLD_DEEPBIND | RTLD_GLOBAL);
    #endif

    if(!dl_handle)
    {
        printf("ERROR: Could not load %s.\n", final_path.c_str());
        return true;
    }

    init_world  = (init_world_func*)dlsym(dl_handle, "init_world");
    
    init_alloc_function_pointers = (init_alloc_function_pointers_func*)dlsym(dl_handle, "init_alloc_function_pointers");

    Omni_UGenConstructor = (Omni_UGenConstructor_func*)dlsym(dl_handle, "UGenConstructor");
    Omni_UGenDestructor  = (Omni_UGenDestructor_func*)dlsym(dl_handle, "UGenDestructor");
    Omni_UGenPerform     = (Omni_UGenPerform_func*)dlsym(dl_handle, "UGenPerform"); 

    //Initialization routines
    init_world((void*)inWorld);
    init_alloc_function_pointers((RTAlloc_ptr*)ft->fRTAlloc, (RTRealloc_ptr*)ft->fRTRealloc, (RTFree_ptr*)ft->fRTFree);

    return true;
}

//needed
void loadFile_cleanup(World* inWorld, void* cmd) {}

void OmniLoadFile(World *inWorld, void* inUserData, struct sc_msg_iter *args, void *replyAddr)
{
    DoAsynchronousCommand(inWorld, replyAddr, nullptr, nullptr, (AsyncStageFn)loadFile, 0, 0, loadFile_cleanup, 0, nullptr);
}

bool CompileFile(World* inWorld, void* cmd)
{
    printf("Compile cmd: %s \n", compile_cmd.c_str());

    std::string compile_result;

    const char* compile_cmd_char = compile_cmd.c_str();

    printf("%s \n", compile_cmd_char);

    FILE* pipe = popen(compile_cmd_char, "r");
    
    if (!pipe) 
    {
        printf("ERROR: Could not run compilation of Sine.Omni\n");
        return true;
    }
    
    //Maximum of 16384 characters.. It should be enough
    char buffer[16384];
    while(!feof(pipe)) 
    {
        while(fgets(buffer, 16383, pipe) != NULL)
            compile_result += buffer;
    }

    pclose(pipe);

    printf("%s\n", compile_result.c_str());

    return true;
}

void compile_sine_cleanup(World* inWorld, void* cmd) {}

void OmniCompileFile(World *inWorld, void* inUserData, struct sc_msg_iter *args, void *replyAddr)
{
    DoAsynchronousCommand(inWorld, replyAddr, nullptr, nullptr, (AsyncStageFn)CompileFile, 0, 0, compile_sine_cleanup, 0, nullptr);
}

void DefineOmniCmds()
{
    DefinePlugInCmd("/load_file", (PlugInCmdFunc)OmniLoadFile, nullptr);
    DefinePlugInCmd("/compile_file", (PlugInCmdFunc)OmniCompileFile, nullptr);
}
*/