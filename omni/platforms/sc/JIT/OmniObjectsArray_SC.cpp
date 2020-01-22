#include "OmniObjectsArray_SC.h"

void OmniObjectsArray_SC::get_omni_objects_list(OmniReply* omni_reply)
{
    omni_reply->create_done_command(omni_reply->get_OSC_unique_id(), "/omni_get_objects_list");
    
    int active_entries = get_active_entries();
    if(!active_entries)
        return;
    
    int entries_count = 0;

    for(int i = 0; i < get_num_total_entries(); i++)
    {
        OmniObject* this_omni_object = get_omni_objects_array() + i;

        if(this_omni_object->compiled)
        {
            //Accumulate results
            omni_reply->create_done_command(this_omni_object->name);
            
            entries_count++;
            
            //Scanned through all active entries.
            if(entries_count == active_entries)
                return;
        }
    }
}

void OmniObjectsArray_SC::get_omni_object_by_name(OmniReplyWithLoadPath* omni_reply)
{
    int active_entries = get_active_entries();
    if(!active_entries)
        return;

    const char* name = omni_reply->get_omni_load_path();

    int entries_count = 0;

    for(int i = 0; i < get_num_total_entries(); i++)
    {
        OmniObject* this_omni_object = get_omni_objects_array() + i;

        if(this_omni_object->compiled)
        {
            if(strcmp(name, (this_omni_object->name).c_str()) == 0)
            {
                int new_id = i;
                //send path in place of name
                omni_reply->create_done_command(omni_reply->get_OSC_unique_id(), "/omni_get_object_by_name", new_id, this_omni_object->path.c_str(), this_omni_object->num_inputs, this_omni_object->num_outputs);
                break;
            }
            
            entries_count++;
            
            //Scanned through all active entries, no success.
            if(entries_count == active_entries)
            {
                printf("WARNING: Unable to find any omni object with name: %s\n", name);
                omni_reply->create_done_command(omni_reply->get_OSC_unique_id(), "/omni_get_object_by_name", -1, "", -1, -1);
                return;
            }
        }
    }
}