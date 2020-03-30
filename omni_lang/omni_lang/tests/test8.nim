import ../../omni_lang

type
    UGen = object
        auto_mem : ptr OmniAutoMem


proc newUGen() : ptr UGen =
    var
        ugen_ptr = alloc(culong(sizeof(UGen))) 
        ugen     = cast[ptr UGen](ugen_ptr)
        
    ugen.auto_mem = allocInitOmniAutoMem()

    return ugen

proc freeUGen(ugen : ptr UGen) : void =
    
    freeOmniAutoMem(ugen.auto_mem)
    
    let ugen_ptr = cast[pointer](ugen)

    dealloc(ugen_ptr)

# TEST

var ugen = newUGen()

var data1 = Data.innerInit(100, 1, float, ugen.auto_mem)
var data2 = Data.innerInit(100, 1, float, ugen.au)

ugen.freeUGen()