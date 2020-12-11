import ../../omni_lang

type
    Omni_UGen = object
        auto_mem : ptr Omni_AutoMem


proc newUGen() : ptr Omni_UGen =
    var
        omni_ugen_ptr = alloc(culong(sizeof(Omni_UGen))) 
        omni_ugen     = cast[ptr Omni_UGen](omni_ugen_ptr)
        
    omni_ugen.auto_mem = omni_create_omni_auto_mem()

    return omni_ugen

proc freeUGen(omni_ugen : ptr Omni_UGen) : void =
    
    omni_auto_mem_free(omni_ugen.auto_mem)
    
    let omni_ugen_ptr = cast[pointer](omni_ugen)

    dealloc(omni_ugen_ptr)

# TEST

var omni_ugen = newUGen()

var data1 = Data.innerInit(100, 1, float, omni_ugen.auto_mem)
var data2 = Data.innerInit(100, 1, float, omni_ugen.au)

omni_ugen.freeUGen()