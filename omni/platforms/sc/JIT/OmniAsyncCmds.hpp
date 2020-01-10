#pragma once

#include <dlfcn.h>     //dlopen, dlclose, etc...
#include <string>      //std::string
#include <unistd.h>    //getpid
#include <sys/stat.h>  //stat

#include "SC_PlugIn.h"
#include "GlobalVariables.h"

#ifdef __APPLE__
    const char* find_Omni_directory_cmd = "i=10; complete_string=$(vmmap -w $serverPID | grep -m 1 'Omni.scx'); file_string=$(awk -v var=\"$i\" '{print $var}' <<< \"$complete_string\"); extra_string=${complete_string%$file_string*}; final_string=${complete_string#\"$extra_string\"}; printf \"%s\" \"${final_string//\"Omni.scx\"/}\"";
#elif __linux__
    const char* find_Omni_directory_cmd = "i=4; complete_string=$(pmap -p $serverPID | grep -m 1 'Omni.so'); file_string=$(awk -v var=\"$i\" '{print $var}' <<< \"$complete_string\"); extra_string=${complete_string%$file_string*}; final_string=${complete_string#\"$extra_string\"}; printf \"%s\" \"${final_string//\"Omni.so\"/}\"";
#endif

void retrieve_omni_dir() 
{
    //Get process id and convert it to string
    pid_t server_pid = getpid();
    const char* server_pid_string = (std::to_string(server_pid)).c_str();

    printf("PID: %i\n", server_pid);

    //Set the serverPID enviromental variable, used in the "find_Omni_directory_cmd" bash script
    setenv("serverPID", server_pid_string, 1);

    //run script and get a FILE pointer back to the result of the script (which is what's returned by printf in bash script)
    FILE* pipe = popen(find_Omni_directory_cmd, "r");
    
    if(!pipe) 
    {
        printf("ERROR: Could not run bash script to find omni's folder in SC path \n");
        return;
    }
    
    //Maximum of 2048 characters.. It should be enough
    char buffer[2048];
    while(!feof(pipe)) 
    {
        while(fgets(buffer, 2048, pipe) != NULL)
            omni_SC_folder_path += buffer;
    }

    pclose(pipe);

    printf("*** omni SC path: %s \n", omni_SC_folder_path.c_str());
}

inline bool file_exists (const std::string& name) 
{
    struct stat buffer;   
    return (stat (name.c_str(), &buffer) == 0); 
}

void DefineOmniCmds()
{
    
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