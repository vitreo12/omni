#include "SC_PlugIn.h"

#include "OmniAsyncCmds.hpp"

struct Omni : public Unit 
{

};

static void Omni_next(Omni* unit, int inNumSamples);
static void Omni_Ctor(Omni* unit);
static void Omni_Dtor(Omni* unit);

void Omni_Ctor(Omni* unit) 
{

}

void Omni_Dtor(Omni* unit) 
{
   
}

void Omni_next(Omni* unit, int inNumSamples) 
{

}

inline void output_silence(Omni* unit, int inNumSamples)
{
    for(int i = 0; i < unit->mNumOutputs; i++)
    {
        for (int y = 0; y < inNumSamples; y++) 
            OUT(i)[y] = 0.0f;
    }
}

PluginLoad(OmniUGens) 
{
    ft = inTable; 

    retrieve_omni_dir();
    
    DefineOmniCmds();

    DefineDtorUnit(Omni);
}