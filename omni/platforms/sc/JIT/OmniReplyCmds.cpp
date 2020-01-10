#include "OmniReplyCmds.h"

/* Reply functions to sclang when a "/done" command is sent from "/omni_load", "/omni_free", etc..
This is where all the inputs/outputs/name informations are sent back to sclang from scsynth */

/**************/
/* OmniReply */
/**************/

OmniReply::OmniReply(int OSC_unique_id_)
{
    count_char = 0;
    OSC_unique_id = OSC_unique_id_;
}

/* Using pointers to the buffer, shifted by count_char. */
int OmniReply::append_string(char* buffer_, size_t size, const char* string)
{
    return snprintf(buffer_, size, "%s\n", string);
}

//for id
int OmniReply::append_string(char* buffer_, size_t size, int value)
{
    return snprintf(buffer_, size, "%i\n", value);
}

//Exit condition. No more VarArgs to consume
void OmniReply::create_done_command() 
{
    return;
}

int OmniReply::get_OSC_unique_id()
{
    return OSC_unique_id;
}

char* OmniReply::get_buffer()
{
    return buffer;
}

/**************************/
/* OmniReplyWithLoadPath */
/**************************/

OmniReplyWithLoadPath::OmniReplyWithLoadPath(int OSC_unique_id_, const char* omni_load_path_) : OmniReply(OSC_unique_id_)
{
    //std::string performs deep copy on char*
    omni_load_path = omni_load_path_;
}

const char* OmniReplyWithLoadPath::get_omni_load_path()
{
    return omni_load_path.c_str();
}

/************************/
/* OmniReceiveObjectId */
/************************/

OmniReceiveObjectId::OmniReceiveObjectId(int omni_object_id_)
{
    omni_object_id = omni_object_id_;
}

int OmniReceiveObjectId::get_omni_object_id()
{
    return omni_object_id;
}