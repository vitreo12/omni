type
    ArrayPtr[T] = ptr UncheckedArray[T]

    SCData[T] = object
        data  : ArrayPtr[T]
        chans : int
        size  : int

#Use the Data interface just in proc
proc Data*[T](size : int, chans : int = 1) : ptr SCData[T] =
    #Actual object. alloc0 should be replaced with RTAlloc
    result   = cast[ptr SCData[T]](alloc0(sizeof(SCData[T])))
    
    #Data of the object (the array). alloc0 should be replaced with RTAlloc.
    let data = cast[ArrayPtr[T]](alloc0(sizeof(ArrayPtr[T]) * size * chans))
    
    result.data  = data
    result.chans = chans
    result.size  = size

#Test if this deallocation method actually works...
proc DisposeData*[T](a : ptr SCData[T]) : void =
    #dealloc should be RTFree
    dealloc(cast[pointer](a.data)) #pointer is void*

#Getter for ptr (constructed from Data[T] proc)
proc `[]`*[I : Ordinal; T](a : ptr SCData[T], i : I) : T {.noSideEffect.} =
    return a.data[i]

#Getter for normal
proc `[]`*[I : Ordinal; T](a : SCData[T], i : I) : T {.noSideEffect.} =
    return a.data[i]

#Setter for ptr (constructed from Data[T] proc)
proc `[]=`*[I : Ordinal; T, S](a : ptr SCData[T], i : I, x : S) : void {.noSideEffect.} =
    a.data[i] = x

#Setter for normal
proc `[]=`*[I : Ordinal; T, S](a : SCData[T], i : I, x : S) : void {.noSideEffect.} =
    a.data[i] = x

########
# TEST #
########

#[ let a = Data[float](10)

echo a[0]

a[0] = 2.13

echo a[0]

DisposeData(a) ]#