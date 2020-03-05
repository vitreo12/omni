#pragma once

#include "OmniObject.h"

/***********************/
/* OmniObjectCompiler */
/***********************/

class OmniObjectCompiler
{
    public:
        OmniObjectCompiler();

        ~OmniObjectCompiler() {}

        bool compile_omni_object(const char* omni_file_path);
        bool unload_omni_object(OmniObject* omni_object);
    
    private:
        const char* compile_cmd;

        void init_omni_object(OmniObject* omni_object);
};