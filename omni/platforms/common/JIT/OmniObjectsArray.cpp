#include "OmniObjectsArray.h"

/* Array of OmniObject*. Fixed size of 1000 (for now) */

/***********************/
/* OmniEntriesCounter */
/***********************/

void OmniEntriesCounter::advance_active_entries()
{
    active_entries++;
}

void OmniEntriesCounter::decrease_active_entries()
{
    active_entries--;
    if(active_entries < 0)
        active_entries = 0;
}

int OmniEntriesCounter::get_active_entries()
{
    return active_entries;
}

/*********************/
/* OmniObjectsArray */
/*********************/
OmniObjectsArray::OmniObjectsArray()
{
    init_omni_objects_array();
}

OmniObjectsArray::~OmniObjectsArray()
{
    destroy_omni_objects_array();
}

//Constructor
void OmniObjectsArray::init_omni_objects_array()
{
    omni_objects_array = (OmniObject*)calloc(num_total_entries, sizeof(OmniObject));
    
    if(!omni_objects_array)
    {
        printf("ERROR:Failed to allocate memory for the OmniObjects class \n");
        return;
    }
}

//Destructor
void OmniObjectsArray::destroy_omni_objects_array()
{
    free(omni_objects_array);
}

/* NRT THREAD. Called at OmniDef.new() */
bool OmniObjectsArray::new_omni_object(const char* omni_file_path)
{  
    int new_id;
    OmniObject* omni_object;
    
    //advance_active_entries();
    
    return true;
}

/* RT THREAD. Called when a Omni UGen is created on the server.
No need to run locks here, as RT execution will only happen if compiler barrier
is inactive anyway: it's already locked from the Omni.cpp code.*/
OmniObjectsArrayState OmniObjectsArray::get_omni_object(int unique_id, OmniObject** omni_object)
{
    //This barrier will be useful when support for resizing the array will be added.
    //bool barrier_acquired = OmniAtomicBarrier::RTTrylock();

    //if(barrier_acquired)
    //{
        OmniObject* this_omni_object = omni_objects_array + unique_id;

        if(this_omni_object->compiled)
            omni_object[0] = this_omni_object;
        else
        {
            //OmniDef compiled for another server.
            printf("WARNING: Invalid object. Perhaps this OmniDef is not valid on this server \n");
            //OmniAtomicBarrier::Unlock();
            return OmniObjectsArrayState::Invalid;
        }

        //OmniAtomicBarrier::Unlock();
        return OmniObjectsArrayState::Free;
    //}
    
    //return OmniObjectsArrayState::Busy;
}

/* NRT THREAD. Called at OmniDef.free() */
void OmniObjectsArray::delete_omni_object(int unique_id)
{
    OmniObject* this_omni_object = omni_objects_array + unique_id;
    
    if(unload_omni_object(this_omni_object))
        decrease_active_entries();
}
