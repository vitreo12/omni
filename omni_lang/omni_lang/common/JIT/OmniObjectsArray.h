#pragma once

#include "OmniObjectCompiler.h"
#include "OmniAtomicBarrier.h"

/* Array of OmniObject*. Fixed size of 1000 (for now) */

/***********************/
/* OmniEntriesCounter */
/***********************/

class OmniEntriesCounter
{
    public:
        void advance_active_entries();
        void decrease_active_entries();
        int get_active_entries();

    private:
        int active_entries = 0;
};

/*********************/
/* OmniObjectsArray */
/*********************/

//For retrieval on RT thread. Busy will only be usde when added support for resizing the array
enum class OmniObjectsArrayState {Busy, Free, Invalid};

//This should be expandable
#define OMNI_OBJECTS_ARRAY_COUNT 1000

/* Allocate it with a unique_ptr? Or just a normal new/delete? */
class OmniObjectsArray : public OmniObjectCompiler, public OmniAtomicBarrier, public OmniEntriesCounter
{
    public:
        OmniObjectsArray();

        ~OmniObjectsArray();

        /* NRT THREAD. Called at OmniDef.new() */
        bool new_omni_object(const char* omni_file_path);

        /* RT THREAD. Called when a Omni UGen is created on the server.
        No need to run locks here, as RT execution will only happen if compiler barrier
        is inactive anyway: it's already locked from the Omni.cpp code.*/
        OmniObjectsArrayState get_omni_object(int unique_id, OmniObject** omni_object);

        /* NRT THREAD. Called at OmniDef.free() */
        void delete_omni_object(int unique_id);

        //Getters for SC/max/pd wrappers
        int get_num_total_entries() { return num_total_entries; }
        OmniObject* get_omni_objects_array() { return omni_objects_array; }

    private:
        
        //Array of OmniObject(s)
        OmniObject* omni_objects_array = nullptr;

        //Fixed size: 1000 entries for the array.
        int num_total_entries = OMNI_OBJECTS_ARRAY_COUNT;

        //Constructor
        void init_omni_objects_array();

        //Destructor
        void destroy_omni_objects_array();
};
