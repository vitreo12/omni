#pragma once

#include "OmniReplyCmds.h"
#include "../../common/JIT/OmniObjectsArray.h"

//SC wrapper for OmniObjectsArray
class OmniObjectsArray_SC : public OmniObjectsArray
{
    public:
        void get_omni_objects_list(OmniReply* omni_reply);
        void get_omni_object_by_name(OmniReplyWithLoadPath* omni_reply);
};