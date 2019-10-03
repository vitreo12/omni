#pragma once

#include <dlfcn.h>
#include <string>
#include <unistd.h>
#include <sys/stat.h>
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

#ifdef __APPLE__
    const char* find_NimCollider_directory_cmd = "i=10; complete_string=$(vmmap -w $serverPID | grep -m 1 'Nim.scx'); file_string=$(awk -v var=\"$i\" '{print $var}' <<< \"$complete_string\"); extra_string=${complete_string%$file_string*}; final_string=${complete_string#\"$extra_string\"}; printf \"%s\" \"${final_string//\"Nim.scx\"/}\"";
#elif __linux__
    const char* find_NimCollider_directory_cmd = "i=4; complete_string=$(pmap -p $serverPID | grep -m 1 'Nim.so'); file_string=$(awk -v var=\"$i\" '{print $var}' <<< \"$complete_string\"); extra_string=${complete_string%$file_string*}; final_string=${complete_string#\"$extra_string\"}; printf \"%s\" \"${final_string//\"Nim.so\"/}\"";
#endif

std::string NimCollider_folder_path;

std::string compile_cmd;

void retrieve_NimCollider_dir() 
{
    //Get process id and convert it to string
    pid_t server_pid = getpid();
    const char* server_pid_string = (std::to_string(server_pid)).c_str();

    printf("PID: %i\n", server_pid);

    //Set the serverPID enviromental variable, used in the "find_NimCollider_directory_cmd" bash script
    setenv("serverPID", server_pid_string, 1);

    //run script and get a FILE pointer back to the result of the script (which is what's returned by printf in bash script)
    FILE* pipe = popen(find_NimCollider_directory_cmd, "r");
    
    if (!pipe) 
    {
        printf("ERROR: Could not run bash script to find Nim \n");
        return;
    }
    
    //Maximum of 2048 characters.. It should be enough
    char buffer[2048];
    while(!feof(pipe)) 
    {
        while(fgets(buffer, 2048, pipe) != NULL)
            NimCollider_folder_path += buffer;
    }

    pclose(pipe);

    printf("*** NimCollider Path: %s \n", NimCollider_folder_path.c_str());

    //Bug: paths with spaces won't work. Need to add trailing backslashes to all spaces.
    #ifdef __APPLE__
        compile_cmd = "/Users/francescocameli/.nimble/bin/nim c --import:math --import:/Users/francescocameli/Desktop/NimCollider/dsp_macros.nim --import:/Users/francescocameli/Desktop/NimCollider/sc_types.nim --import:/Users/francescocameli/Desktop/NimCollider/SC/sc_data.nim  --import:/Users/francescocameli/Desktop/NimCollider/SC/sc_buffer.nim --import:/Users/francescocameli/Desktop/NimCollider/SC/RTAlloc/rt_alloc.nim --import:/Users/francescocameli/Desktop/NimCollider/dsp_print.nim --app:lib --gc:none --noMain -d:supercollider -d:release -d:danger --checks:off --assertions:off --opt:speed --stdout:on --deadCodeElim:on /Users/francescocameli/Library/Application\\ Support/SuperCollider/Extensions/NimCollider/Sine.nim";
    #elif __linux__
        compile_cmd = "nim c --import:math --import:/home/francesco/Sources/NimCollider/dsp_macros.nim --import:/home/francesco/Sources/NimCollider/sc_types.nim --import:/home/francesco/Sources/NimCollider/SC/sc_data.nim  --import:/home/francesco/Sources/NimCollider/SC/sc_buffer.nim --import:/home/francesco/Sources/NimCollider/SC/RTAlloc/rt_alloc.nim --import:/home/francesco/Sources/NimCollider/dsp_print.nim --app:lib --gc:none --noMain -d:supercollider -d:release -d:danger --checks:off --assertions:off --opt:speed --stdout:on --deadCodeElim:on " + NimCollider_folder_path + "Sine.nim";
        //compile_cmd = "nim c --import:math --import:/home/francesco/Sources/NimCollider/dsp_macros.nim --import:/home/francesco/Sources/NimCollider/sc_types.nim --import:/home/francesco/Sources/NimCollider/SC/sc_data.nim  --import:/home/francesco/Sources/NimCollider/SC/sc_buffer.nim --import:/home/francesco/Sources/NimCollider/SC/RTAlloc/rt_alloc.nim --import:/home/francesco/Sources/NimCollider/dsp_print.nim --app:lib --gc:none --noMain -d:supercollider -d:release -d:danger --checks:off --assertions:off --opt:speed --stdout:on --deadCodeElim:on --hints:off --warning[UnusedImport]:off " + NimCollider_folder_path + "Sine.nim";
    #endif
}

inline bool file_exists (const std::string& name) 
{
  struct stat buffer;   
  return (stat (name.c_str(), &buffer) == 0); 
}

bool loadLibSine(World* inWorld, void* cmd)
{
    std::string final_path;

    if(dl_handle)
        dlclose(dl_handle);

    #ifdef __APPLE__
        final_path = NimCollider_folder_path + "libSine.dylib";
        
        if(!file_exists(final_path))
        {
            printf("ERROR: %s doesn't exist \n", final_path.c_str());
            return true;
        }

        dl_handle = dlopen(final_path.c_str(), RTLD_GLOBAL);
    #elif __linux__
        final_path = NimCollider_folder_path + "libSine.so";

        if(!file_exists(final_path))
        {
            printf("ERROR: %s doesn't exist \n", final_path.c_str());
            return true;
        }

        dl_handle = dlopen(final_path.c_str(), RTLD_NOW | RTLD_DEEPBIND | RTLD_GLOBAL);
    #endif

    if(!dl_handle)
    {
        printf("ERROR: Could not load libSine.so/dylib.\n");
        return true;
    }

    printf("*** libSine.so/dylib correctly loaded.\n");

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

void NimLoadSine(World *inWorld, void* inUserData, struct sc_msg_iter *args, void *replyAddr)
{
    DoAsynchronousCommand(inWorld, replyAddr, nullptr, nullptr, (AsyncStageFn)loadLibSine, 0, 0, loadLibSine_cleanup, 0, nullptr);
}

bool compileSine(World* inWorld, void* cmd)
{
    printf("Compile cmd: %s \n", compile_cmd.c_str());

    std::string compile_result;

    const char* compile_cmd_char = compile_cmd.c_str();

    printf("%s \n", compile_cmd_char);

    FILE* pipe = popen(compile_cmd_char, "r");
    
    if (!pipe) 
    {
        printf("ERROR: Could not run compilation of Sine.nim\n");
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

void NimCompileSine(World *inWorld, void* inUserData, struct sc_msg_iter *args, void *replyAddr)
{
    DoAsynchronousCommand(inWorld, replyAddr, nullptr, nullptr, (AsyncStageFn)compileSine, 0, 0, compile_sine_cleanup, 0, nullptr);
}

void DefineNimCmds()
{
    DefinePlugInCmd("/load_sine", (PlugInCmdFunc)NimLoadSine, nullptr);
    DefinePlugInCmd("/compile_sine", (PlugInCmdFunc)NimCompileSine, nullptr);
}