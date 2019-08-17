import math

type Phasor = object
    phase : float
    somethingElse : float

type
    signal*       = float
    signal64*     = float64
    signal32*     = float32
    CFloatPtr*    = ptr UncheckedArray[cfloat]      #float*
    CFloatPtrPtr* = ptr UncheckedArray[CFloatPtr]   #float**

type
    UGen {.inject.} = object
        phase_var: float
        sampleRate_let: float
        phasor_let: Phasor

proc UGenConstructor(): ptr UGen {.exportc: "UGenConstructor".} =
    let
        sampleRate_let = 48000.0
        phasor_let = Phasor(phase : 0.3, somethingElse : 0.32)
    
    var phase_var = 0.0
    var ugen: ptr UGen = cast[ptr UGen](alloc(cast[culong](40)))
    
    ugen.phase_var = phase_var
    ugen.sampleRate_let = sampleRate_let
    ugen.phasor_let = phasor_let

#[     let phasor_ptr = unsafeAddr ugen.phasor_let
    phasor_ptr.phase = 0.3
    phasor_ptr.somethingElse = 0.23 ]#

    return ugen

proc UGenDestructor(ugen126157: ptr UGen): void {.exportc: "UGenDestructor".} =
    let ugen_void_cast126158 = cast[pointer](ugen126157)
    if not isNil(ugen_void_cast126158):
        dealloc(ugen_void_cast126158)
  

proc UGenPerform(ugen: ptr UGen; buf_size: cint; ins_SC: ptr ptr cfloat; outs_SC: ptr ptr cfloat): void {.exportc: "UGenPerform".} =
    let
        phase_var = unsafeAddr ugen.phase_var
        sampleRate = ugen.sampleRate_let
        phasor = unsafeAddr ugen.phasor_let

    let
        ins_Nim: CFloatPtrPtr = cast[CFloatPtrPtr](ins_SC)
        outs_Nim: CFloatPtrPtr = cast[CFloatPtrPtr](outs_SC)
        
    var
        frequency: float
        sine_out: float

    for audio_index_loop in 0 .. buf_size:
        frequency = ins_Nim[0][audio_index_loop]
        if 1.0 <= phase_var[]:
            phase_var[] = 0.0

        phasor.phase = phase_var[]
        
        sine_out = cos(phase_var[] * 2 * 3.141592653589793)
        outs_Nim[0][audio_index_loop] = sine_out
        phase_var[] += abs(frequency) / (sampleRate - 1)