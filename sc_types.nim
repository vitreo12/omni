type
    Signal*       = float32
    Signal64*     = float64
    Signal32*     = float32
    CFloatPtr*    = ptr UncheckedArray[cfloat]      #float*
    CFloatPtrPtr* = ptr UncheckedArray[CFloatPtr]   #float**