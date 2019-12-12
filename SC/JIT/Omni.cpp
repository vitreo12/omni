#include "SC_PlugIn.h"

#include "OmniCmds.hpp"

struct Omni : public Unit 
{
    void* sine_Omni_obj;
};

static void Omni_next(Omni* unit, int inNumSamples);
static void Omni_Ctor(Omni* unit);
static void Omni_Dtor(Omni* unit);

void Omni_Ctor(Omni* unit) 
{
    if(Omni_UGenConstructor)
        unit->sine_Omni_obj = (void*)Omni_UGenConstructor(unit->mInBuf);
    else
    {
        Print("ERROR: No libsine.so/dylib loaded\n");
        unit->sine_Omni_obj = nullptr;
    }

    SETCALC(Omni_next);
    
    Omni_next(unit, 1);
}

void Omni_Dtor(Omni* unit) 
{
    if(unit->sine_Omni_obj)
        Omni_UGenDestructor(unit->sine_Omni_obj);
}

void Omni_next(Omni* unit, int inNumSamples) 
{
    if(unit->sine_Omni_obj)
        Omni_UGenPerform(unit->sine_Omni_obj, inNumSamples, unit->mInBuf, unit->mOutBuf);
    else
    {
        for(int i = 0; i < unit->mNumOutputs; i++)
        {
            for(int y = 0; y < inNumSamples; y++)
                unit->mOutBuf[i][y] = 0.0f;
        }
    }
}

PluginLoad(OmniUGens) 
{
    ft = inTable; 

    retrieve_OmniCollider_dir();
    
    DefineOmniCmds();
    DefineDtorUnit(Omni);
}