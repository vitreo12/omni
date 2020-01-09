#include "SC_PlugIn.h"

#include "OmniCmds.hpp"

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

PluginLoad(OmniUGens) 
{
    ft = inTable; 

    retrieve_Omni_dir();
    
    DefineOmniCmds();

    DefineDtorUnit(Omni);
}