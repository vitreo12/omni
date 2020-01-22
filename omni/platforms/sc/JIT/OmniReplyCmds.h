#pragma once

#include "RTClassAlloc.hpp"
#include <string>

/* Reply functions to sclang when a "/done" command is sent from "/omni_load", "/omni_free", etc..
This is where all the inputs/outputs/name informations are sent back to sclang from scsynth */

//Not the safest way. GetOmniDefs could simply run out of the characters
#define OMNI_CHAR_BUFFER_SIZE 1000

/**************/
/* OmniReply */
/**************/

class OmniReply : public RTClassAlloc
{
    public:
        OmniReply(int OSC_unique_id_);

        ~OmniReply(){}

        /* Using pointers to the buffer, shifted by count_char. */
        int append_string(char* buffer_, size_t size, const char* string);
        
        //for id
        int append_string(char* buffer_, size_t size, int value);

        //Exit condition. No more VarArgs to consume
        void create_done_command();

        template<typename T, typename... VarArgs>
        void create_done_command(T&& arg, VarArgs&&... args);

        int get_OSC_unique_id();

        char* get_buffer();

    private:
        char buffer[OMNI_CHAR_BUFFER_SIZE];
        int count_char;
        int OSC_unique_id; //sent from SC. used for OSC parsing
};

//Needs to be in same file of declaration...
template<typename T, typename... VarArgs>
void OmniReply::create_done_command(T&& arg, VarArgs&&... args)
{    
    //Append string to the end of the previous one. Keep count of the position with "count_char"
    count_char += append_string(buffer + count_char, OMNI_CHAR_BUFFER_SIZE - count_char, arg); //std::forward<T>(arg...) ?

    //Call function recursively
    if(count_char && count_char < OMNI_CHAR_BUFFER_SIZE)
        create_done_command(args...); //std::forward<VarArgs>(args...) ?
}

/**************************/
/* OmniReplyWithLoadPath */
/**************************/

class OmniReplyWithLoadPath : public OmniReply
{
    public:
        OmniReplyWithLoadPath(int OSC_unique_id_, const char* omni_load_path_);

        const char* get_omni_load_path();

    private:
        std::string omni_load_path;
};

/************************/
/* OmniReceiveObjectId */
/************************/

class OmniReceiveObjectId : public RTClassAlloc
{
    public:
        OmniReceiveObjectId(int omni_object_id_);

        int get_omni_object_id();

    private:
        int omni_object_id;
};
