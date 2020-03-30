import ../alloc/omni_alloc
import ../auto_mem/omni_auto_mem
import ../print/omni_print

type
    ArrayPtr[T] = ptr UncheckedArray[T]

    Data_obj[T] = object
        data  : ArrayPtr[T]
        size  : uint
        chans : uint
        size_X_chans : uint

    #Only export Data
    Data*[T] = ptr Data_obj[T]

    #Should be more generic. Only accept numbers for now.
    #SomeData* = Data[float] or Data[float32] or Data[float64] or Data[int] or Data[int8] or Data[int16] or Data[int32] or Data[int64] or Data[uint] or Data[uint8] or Data[uint16] or Data[uint32] or Data[uint64]
        
#Having the strings as const as --gc:none is used
const
    size_error   = "WARNING: Data's size must be a positive number. Setting it to 1"
    chans_error  = "WARNING: Data's chans must be a positive number. Setting it to 1"
    #bounds_error = "WARNING: Trying to access out of bounds Data."

#Constructor interface: Data
proc innerInit*[S : SomeInteger, C : SomeInteger](obj_type : typedesc[Data], size : S = uint(1), chans : C = uint(1), dataType : typedesc = typedesc[float], ugen_auto_mem : ptr OmniAutoMem) : Data[dataType] =
    
    #error out if trying to instantiate any dataType that is not a Number
    when dataType isnot SomeNumber: 
        {.fatal: "Data's dataType must be SomeNumber".}

    var 
        real_size  = size
        real_chans = chans
    
    if real_size < 1:
        print(size_error)
        real_size = 1

    if real_chans < 1:
        print(chans_error)
        real_chans = 1

    let 
        size_uint     = uint(real_size)
        chans_uint    = uint(real_chans)
        size_data_obj = sizeof(Data_obj[dataType])

    #Actual object, assigned to result
    result = cast[Data[dataType]](omni_alloc(culong(size_data_obj)))
    
    #Data of the object (the array)
    let 
        size_data_type_uint    = uint(sizeof(dataType))
        size_X_chans_uint      = size_uint * chans_uint
        total_size_uint        = size_data_type_uint * size_X_chans_uint
        data                   = cast[ArrayPtr[dataType]](omni_alloc0(culong(total_size_uint)))

    ugen_auto_mem.registerChild(result)
    ugen_auto_mem.registerChild(data)
    
    #Fill the object layout
    result.data         = data
    result.chans        = chans_uint
    result.size         = size_uint
    result.size_X_chans = size_X_chans_uint

template new*[S : SomeInteger, C : SomeInteger](obj_type : typedesc[Data], size : S = uint(1), chans : C = uint(1), dataType : typedesc = typedesc[float]) : untyped {.dirty.} =
    innerInit(Data, size, chans, dataType, ugen_auto_mem)

#Deallocation proc
proc destructor*[T](obj : Data[T]) : void =
    print("Calling Data's destructor")

    let 
        obj_ptr  = cast[pointer](obj)
        data_ptr = cast[pointer](obj.data)

    omni_free(data_ptr)     #dealloc the data
    omni_free(obj_ptr)      #dealloc actual object
   

##########
# GETTER #
##########

#1 channel
#proc `[]`*[I : SomeInteger, T](a : Data[T] or Data_obj[T], i : I) : T 
proc `[]`*[I : SomeNumber, T](a : Data[T], i : I) : T =
    let 
        data       = a.data
        data_size  = a.size

    if i >= 0:
        if int(i) < int(data_size):
            return data[i]
    else:
        #print(bounds_error)
        return T(0)  #This should probably just raise an error here. Not everything is convertible to 0. Imagine to use Data for something else than numbers, like objects.

#more than 1 channel
#proc `[]`*[I1 : SomeInteger, I2 : SomeInteger; T](a : Data[T] or Data_obj[T], i1 : I1, i2 : I2) : T =
proc `[]`*[I1 : SomeNumber, I2 : SomeNumber; T](a : Data[T], i1 : I1, i2 : I2) : T =
    let 
        data              = a.data
        data_size         = a.size
        data_size_X_chans = a.size_X_chans
        index             = (int(i1) * int(data_size)) + int(i2)
    
    if index >= 0:
        if int(index) < int(data_size_X_chans):
            return data[index]
    else:
        #print(bounds_error)
        return T(0) #This should probably just raise an error here. Not everything is convertible to 0. Imagine to use Data for something else than numbers, like objects.

##########
# SETTER #
##########

#1 channel   
#proc `[]=`*[I : SomeInteger, T, S](a : Data[T] or var Data_obj[T], i : I, x : S) : void =    
proc `[]=`*[I : SomeNumber, T, S](a : Data[T], i : I, x : S) : void =
    let 
        data      = a.data
        data_size = a.size

    if i >= 0:
        if int(i) < int(data_size):
            data[i] = x   
    #else:
    #    print(bounds_error)

#more than 1 channel
#proc `[]=`*[I1 : SomeInteger, I2 : SomeInteger; T, S](a : Data[T] or var Data_obj[T], i1 : I1, i2 : I2, x : S) : void =
proc `[]=`*[I1 : SomeNumber, I2 : SomeNumber; T, S](a : Data[T], i1 : I1, i2 : I2, x : S) : void =
    let 
        data              = a.data
        data_size         = a.size
        data_size_X_chans = a.size_X_chans
        index             = (int(i1) * int(data_size)) + int(i2)
        
    if index >= 0:
        if int(index) < int(data_size_X_chans):
            data[index] = x
    #else:
    #    print(bounds_error)