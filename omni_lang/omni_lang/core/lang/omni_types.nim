type
    Signal*        = float
    Signal64*      = float64
    Signal32*      = float32
    CFloatPtr*     = ptr UncheckedArray[cfloat]       #float*
    CFloatPtrPtr*  = ptr UncheckedArray[CFloatPtr]    #float**
    CDoublePtr*    = ptr UncheckedArray[cdouble]      #double*
    CDoublePtrPtr* = ptr UncheckedArray[CDoublePtr]   #double**