import rt_alloc

type
    C_size_t = culong

    ArrayPtr[T] = ptr UncheckedArray[T]

    Data_obj[T] = object
        data  : ArrayPtr[T]
        size  : uint
        chans : uint
        size_X_chans : uint

    #Only export Data
    Data*[T] = ptr Data_obj[T]

    #Should be more generic. Only accept numbers for now.
    SomeData* = Data[float] or Data[float32] or Data[float64] or Data[int] or Data[int8] or Data[int16] or Data[int32] or Data[int64] or Data[uint] or Data[uint8] or Data[uint16] or Data[uint32] or Data[uint64]
        
#Having the strings as const as --gc:none is used
const
    size_error  = "Data\'s size must be a positive number. Setting it to 1"
    chans_error = "Data\'s chans must be a positive number. Setting it to 1"

#Constructor interface: Data
proc init*[S : SomeInteger, C : SomeInteger](obj_type : typedesc[Data], size : S = uint(1), chans : C = uint(1), dataType : typedesc = typedesc[float]) : Data[dataType] =
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
        size_uint     = cast[uint](real_size)
        chans_uint    = cast[uint](real_chans)
        size_data_obj = sizeof(Data_obj[dataType])

    #Actual object, assigned to result
    result = cast[Data[dataType]](rt_alloc(cast[C_size_t](size_data_obj)))
    
    #Data of the object (the array)
    let 
        size_data_type_uint    = cast[uint](sizeof(dataType))
        size_X_chans_uint      = size_uint * chans_uint
        total_size_uint        = size_data_type_uint * size_X_chans_uint
        data = cast[ArrayPtr[dataType]](rt_alloc0(cast[C_size_t](total_size_uint)))
    
    #Fill the object layout
    result.data         = data
    result.chans        = chans_uint
    result.size         = size_uint
    result.size_X_chans = size_X_chans_uint

#Deallocation proc
proc destructor*[T](obj : Data[T]) : void =
    echo "Calling Data's destructor"

    let 
        obj_void_cast  = cast[pointer](obj)
        data_void_cast = cast[pointer](obj.data)

    rt_free(data_void_cast)     #dealloc the data
    rt_free(obj_void_cast)      #dealloc actual object
   

##########
# GETTER #
##########

#1 channel
proc `[]`*[I : SomeInteger, T](a : Data[T] or Data_obj[T], i : I) : T =
    let 
        data       = a.data
        data_size  = a.size

    if i >= 0 and i < data_size:
        return data[i]
    else:
        return T(0)  #This should probably just raise an error here. Not everything is convertible to 0. Imagine to use Data for something else than numbers, like objects.

#more than 1 channel
proc `[]`*[I1 : SomeInteger, I2 : SomeInteger; T](a : Data[T] or Data_obj[T], i1 : I1, i2 : I2) : T =
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
proc `[]=`*[I : SomeInteger, T, S](a : Data[T] or var Data_obj[T], i : I, x : S) : void =
    let 
        data      = a.data
        data_size = a.size

    if i >= 0 and i < data_size:
        data[i] = x   

#more than 1 channel
proc `[]=`*[I1 : SomeInteger, I2 : SomeInteger; T, S](a : Data[T] or var Data_obj[T], i1 : I1, i2 : I2, x : S) : void =
    let 
        data              = a.data
        data_size         = a.size
        data_size_X_chans = a.size_X_chans
        index             = (i1 * data_size) + i2
        
    if index >= 0 and index < data_size_X_chans:
        data[index] = x