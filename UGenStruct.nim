type
    CFloatPtr    = ptr UncheckedArray[cfloat]
    CFloatPtrPtr = ptr UncheckedArray[CFloatPtr]

    #Built at UGen instantiation
    UGenStruct = object
        inputs  : int
        outputs : int
        sample_rate : cdouble
        # all other user defined stuff here #

proc dummy_perform_fun(ugen_object : ptr UGenStruct, buf_size : cint, ins_SC : ptr ptr cfloat, outs_SC : ptr ptr cfloat) : void =
    var 
        ins  : CFloatPtrPtr = cast[CFloatPtrPtr](ins_SC)
        outs : CFloatPtrPtr = cast[CFloatPtrPtr](outs_SC)

    #Rest of DSP function...
    for audio_index_loop in 0..buf_size:
        discard