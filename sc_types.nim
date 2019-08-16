type
    signal*       = float
    signal64*     = float64
    signal32*     = float32
    CFloatPtr*    = ptr UncheckedArray[cfloat]      #float*
    CFloatPtrPtr* = ptr UncheckedArray[CFloatPtr]   #float**