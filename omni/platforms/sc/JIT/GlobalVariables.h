#pragma once

#include "SC_PlugIn.hpp"

#include "OmniObjectsArray_SC.h"
#include "../../common/JIT/OmniAtomicBarrier.h"

/* INTERFACE TABLE */
static InterfaceTable* ft;

/* OBJECT COMPILER AND ARRAY OF OmniObject* */
extern OmniAtomicBarrier*    omni_compiler_barrier;
extern OmniObjectsArray_SC*  omni_objects_array;

extern std::string omni_SC_folder_path;