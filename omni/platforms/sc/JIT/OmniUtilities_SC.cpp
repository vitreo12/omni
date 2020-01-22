#include "OmniUtilities_SC.h"


void OmniUtilities_SC::retrieve_omni_dir() 
{
    //Get process id and convert it to string
    pid_t server_pid = getpid();
    const char* server_pid_string = (std::to_string(server_pid)).c_str();

    printf("PID: %i\n", server_pid);

    //Set the serverPID enviromental variable, used in the "find_Omni_directory_cmd" bash script
    setenv("serverPID", server_pid_string, 1);

    //run script and get a FILE pointer back to the result of the script (which is what's returned by printf in bash script)
    FILE* pipe = popen(find_omni_directory_cmd, "r");
    
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

bool OmniUtilities_SC::file_exists (const std::string& name) 
{
    struct stat buffer;   
    return (stat (name.c_str(), &buffer) == 0); 
}
