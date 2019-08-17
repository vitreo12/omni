import rt_alloc

type
    C_size_t = culong

    ArrayPtr[T] = ptr UncheckedArray[T]

    SCData[T] = object
        data  : ArrayPtr[T]
        size  : uint
        chans : uint
        size_X_chans : uint

#Having the strings as const as --gc:none is used
const
    size_error  = "Size must be a positive number. Setting it to 1"
    chans_error = "Chans must be a positive number. Setting it to 1"

#Constructor interface: Data
proc Data*[S : SomeInteger, C : SomeInteger](size : S = uint(1), chans : C = uint(1), dataType : typedesc = typedesc[float]) : ptr SCData[dataType] =
    var 
        real_size  = size
        real_chans = chans
    
    if real_size < 1:
        echo size_error
        real_size = 1

    if real_chans < 1:
        echo chans_error
        real_chans = 1

    let 
        size_uint    = cast[uint](real_size)
        chans_uint   = cast[uint](real_chans)
        size_sc_data = sizeof(SCData[dataType])

    #Actual object, assigned to result
    result = cast[ptr SCData[dataType]](rt_alloc(cast[C_size_t](size_sc_data)))
    
    #Data of the object (the array)
    let 
        size_data_type_uint = cast[uint](sizeof(dataType))
        size_X_chans_uint      = size_uint * chans_uint
        total_size_uint        = size_data_type_uint * size_X_chans_uint
        data = cast[ArrayPtr[dataType]](rt_alloc0(cast[C_size_t](total_size_uint)))
    
    #Fill the object layout
    result.data         = data
    result.chans        = chans_uint
    result.size         = size_uint
    result.size_X_chans = size_X_chans_uint

#Deallocation proc
proc DisposeData*[T](a : ptr SCData[T]) : void =
    rt_free(cast[pointer](a.data)) #dealloc the data
    rt_free(cast[pointer](a))      #dealloc actual object

##########
# GETTER #
##########

#1 channel
proc `[]`*[I : SomeInteger, T](a : ptr SCData[T] or SCData[T], i : I) : T =
    let 
        data       = a.data
        data_size  = a.size

    if i >= 0 and i < data_size:
        return data[i]
    else:
        return T(0)  #This should probably just raise an error here. Not everything is convertible to 0. Imagine to use Data for something else than numbers, like objects.

#more than 1 channel
proc `[]`*[I1 : SomeInteger, I2 : SomeInteger; T](a : ptr SCData[T] or SCData[T], i1 : I1, i2 : I2) : T =
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
proc `[]=`*[I : SomeInteger, T, S](a : ptr SCData[T] or var SCData[T], i : I, x : S) : void =
    let 
        data      = a.data
        data_size = a.size

    if i >= 0 and i < data_size:
        data[i] = x   

#more than 1 channel
proc `[]=`*[I1 : SomeInteger, I2 : SomeInteger; T, S](a : ptr SCData[T] or var SCData[T], i1 : I1, i2 : I2, x : S) : void =
    let 
        data              = a.data
        data_size         = a.size
        data_size_X_chans = a.size_X_chans
        index             = (i1 * data_size) + i2
        
    if index >= 0 and index < data_size_X_chans:
        data[index] = x