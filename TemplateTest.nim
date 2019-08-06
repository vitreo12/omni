import macros
import macrosDSP
import typesSC
import math
    
ins 1:
    "freq"

outs 1:
    "sine_out"

type
    Phasor[T] = object
        p : T

constructor:
    let 
        sampleRate = 48000.0
        phasor = Phasor[float64]()
    
    new phasor, sampleRate

expandMacros:
    perform:
        var 
            frequency : float
            phase : float
            sine_out : float

        sample:
            phase = phasor.p
            frequency = in1

            if phase >= 1.0:
                phase = 0.0
            
            sine_out = cos(phase * 2 * PI)
            
            out1 = sine_out

            phase += abs(frequency) / (sampleRate - 1)

            phasor.p = phase


#################
# TESTING SUITE #
#################
#[
var 
    ins_ptr_void  = alloc0(sizeof(ptr cfloat) * 2)      #float**
    in_ptr1_void = alloc0(sizeof(cfloat) * 512)         #float*

    ins_ptr_SC = cast[ptr ptr cfloat](ins_ptr_void)
    ins_ptr = cast[CFloatPtrPtr](ins_ptr_void)
    in_ptr1 = cast[CFloatPtr](in_ptr1_void)

    outs_ptr_void  = alloc0(sizeof(ptr cfloat) * 2)     #float**
    out_ptr1_void = alloc0(sizeof(cfloat) * 512)        #float*
    
    outs_ptr_SC = cast[ptr ptr cfloat](outs_ptr_void)
    outs_ptr = cast[CFloatPtrPtr](outs_ptr_void)
    out_ptr1 = cast[CFloatPtr](out_ptr1_void)

ins_ptr[0]  = in_ptr1
outs_ptr[0] = out_ptr1

var ugen = UGenConstructor()

UGenPerform(ugen, cast[cint](512), ins_ptr_SC, outs_ptr_SC)

dealloc(ins_ptr_void)
dealloc(in_ptr1_void)
dealloc(outs_ptr_void)
dealloc(out_ptr1_void)
]#