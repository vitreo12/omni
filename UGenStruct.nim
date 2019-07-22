type
    CFloatPtr    = ptr UncheckedArray[cfloat]
    CFloatPtrPtr = ptr UncheckedArray[CFloatPtr]

    #Built at UGen instantiation
    UGenStruct = object
        ins  : int
        outs : int
        ins_array   : CFloatPtrPtr     #These would initialize to a null ptr when creating the object
        outs_array  : CFloatPtrPtr
        sample_rate : cdouble

#Called from C at start of each audio loop
proc assign_ins_outs_arrays(ugen_object : var UGenStruct, buf_size : cint, ins : CFloatPtrPtr, outs : CFloatPtrPtr) =
    for s in 0..buf_size:
        for c_i in 0..ugen_object.ins:
            ugen_object.ins_array[c_i][s]  = ins[c_i + 1][s]  #Excluding first UGen input, which is the unique id
        
        for c_o in 0..ugen_object.outs:
            ugen_object.outs_array[c_o][s] = outs[c_o][s]