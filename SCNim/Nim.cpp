#include "SC_PlugIn.h"

#include "NimCmds.hpp"

struct Nim : public Unit 
{
    void* sine_nim_obj;
};

static void Nim_next(Nim* unit, int inNumSamples);
static void Nim_Ctor(Nim* unit);
static void Nim_Dtor(Nim* unit);

void Nim_Ctor(Nim* unit) 
{
    unit->sine_nim_obj = (void*)Nim_UGenConstructor(unit->mInBuf);

    SETCALC(Nim_next);
    Nim_next(unit, 1);
}

void Nim_Dtor(Nim* unit) 
{
    Nim_UGenDestructor(unit->sine_nim_obj);
}

void Nim_next(Nim* unit, int inNumSamples) 
{
    Nim_UGenPerform(unit->sine_nim_obj, inNumSamples, unit->mInBuf, unit->mOutBuf);
}

PluginLoad(NimUGens) 
{
    ft = inTable; 

    retrieve_NimCollider_dir();
    
    DefineNimCmds();
    DefineDtorUnit(Nim);
}