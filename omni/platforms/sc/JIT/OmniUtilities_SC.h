#include <string>      //std::string
#include <unistd.h>    //getpid
#include <sys/stat.h>  //stat

class OmniUtilities_SC 
{
    public:
        OmniUtilities_SC(){}
        ~OmniUtilities_SC(){}

        void retrieve_omni_dir();
        bool file_exists (const std::string& name);

    private:
        std::string omni_SC_folder_path;

        #ifdef __APPLE__
            const char* find_omni_directory_cmd = "i=10; complete_string=$(vmmap -w $serverPID | grep -m 1 'Omni.scx'); file_string=$(awk -v var=\"$i\" '{print $var}' <<< \"$complete_string\"); extra_string=${complete_string%$file_string*}; final_string=${complete_string#\"$extra_string\"}; printf \"%s\" \"${final_string//\"Omni.scx\"/}\"";
        #elif __linux__
            const char* find_omni_directory_cmd = "i=4; complete_string=$(pmap -p $serverPID | grep -m 1 'Omni.so'); file_string=$(awk -v var=\"$i\" '{print $var}' <<< \"$complete_string\"); extra_string=${complete_string%$file_string*}; final_string=${complete_string#\"$extra_string\"}; printf \"%s\" \"${final_string//\"Omni.so\"/}\"";
        #endif
};