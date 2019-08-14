type
    ArrayPtr[T] = ptr UncheckedArray[T]

    SCData[T] = object
        data  : ArrayPtr[T]
        size  : int
        chans : int
        size_X_chans : int

#Constructor interface: Data
proc Data*(size : int = 1, chans : int = 1, dataType : typedesc = typedesc[float]) : ptr SCData[dataType] =
    var 
        real_size  = size
        real_chans = chans
    
    if real_size < 1:
        #echo "Size must be a positive number. Setting it to 1"
        real_size = 1

    if real_chans < 1:
        #echo "Chans must be a positive number. Setting it to 1"
        real_chans = 1

    #Actual object. alloc should be replaced with RTAlloc
    result   = cast[ptr SCData[dataType]](alloc(sizeof(SCData[dataType])))
    
    #Data of the object (the array). alloc0 should be replaced with RTAlloc.
    let data = cast[ArrayPtr[dataType]](alloc0(sizeof(ArrayPtr[dataType]) * size * chans))
    
    result.data         = data
    result.chans        = real_chans
    result.size         = real_size
    result.size_X_chans = real_size * real_chans

#Deallocation proc
proc DisposeData*[T](a : ptr SCData[T]) : void =
    #dealloc should be RTFree
    dealloc(cast[pointer](a.data)) #dealloc the data
    dealloc(cast[pointer](a))      #dealloc actual object

##########
# GETTER #
##########

#1 channel
proc `[]`*[I : Ordinal, T](a : ptr SCData[T] or SCData[T], i : I) : T =
    let 
        data       = a.data
        data_size  = a.size

    if i >= 0 and i < data_size:
        return data[i]
    else:
        return T(0)  #This should probably just raise an error here. Not everything is convertible to 0. Imagine to use Data for something else than numbers, like objects.

#more than 1 channel
proc `[]`*[I1 : Ordinal, I2 : Ordinal; T](a : ptr SCData[T] or SCData[T], i1 : I1, i2 : I2) : T =
    let 
        data              = a.data
        data_size         = a.size
        data_size_X_chans = a.size_X_chans
        index             = (i1 * data_size) + i2
    
    if index >= 0 and index < data_size_X_chans:
        return data[index]
    else:
        return T(0) #This should probably just raise an error here. Not everything is convertible to 0. Imagine to use Data for something else than numbers, like objects.

##########
# SETTER #
##########

#1 channel       
proc `[]=`*[I : Ordinal, T, S](a : ptr SCData[T] or var SCData[T], i : I, x : S) : void =
    let 
        data      = a.data
        data_size = a.size

    if i >= 0 and i < data_size:
        data[i] = x   

#more than 1 channel
proc `[]=`*[I1 : Ordinal, I2 : Ordinal; T, S](a : ptr SCData[T] or var SCData[T], i1 : I1, i2 : I2, x : S) : void =
    let 
        data              = a.data
        data_size         = a.size
        data_size_X_chans = a.size_X_chans
        index             = (i1 * data_size) + i2
        
    if index >= 0 and index < data_size_X_chans:
        data[index] = x

########
# TEST #
########

#[ let a = Data(10, 2)

echo a[0, 5]

#Same as a[0, 0] for multichannel Data
a[0, 5] = 2.13

echo a[0, 5]

DisposeData(a) ]#