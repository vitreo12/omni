# MIT License
# 
# Copyright (c) 2020 Francesco Cameli
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.codi

import ../../lang/omni_call_types
import ../alloc/omni_alloc
import ../auto_mem/omni_auto_mem
import ../print/omni_print
import ../math/omni_math

type
    ArrayPtr[T] = ptr UncheckedArray[T]

    Data_struct_inner*[T] = object
        data    : ArrayPtr[T]
        length  : int
        chans   : int
        length_X_chans : int

    Data*[T] = ptr Data_struct_inner[T]
     
#Having the strings as const as --gc:none is used
const
    length_error = "WARNING: Data's length must be a positive number. Setting it to 1"
    chans_error  = "WARNING: Data's chans must be a positive number. Setting it to 1"

    #bounds_error = "WARNING: Trying to access out of bounds Data."

#Constructor interface: Data
proc struct_new_inner*[S : SomeNumber, C : SomeNumber](obj_type : typedesc[Data_struct_inner], length : S = int(1), chans : C = int(1), dataType : typedesc = typedesc[float], ugen_auto_mem : ptr OmniAutoMem, ugen_call_type : typedesc[CallType] = InitCall) : Data[dataType]  {.inline.} =
    #Trying to allocate in perform block! nonono
    when ugen_call_type is PerformCall:
        {.fatal: "attempting to allocate memory in the `perform` or `sample` blocks for `struct Data`".}
    
    var 
        real_length = int(length)
        real_chans  = int(chans)
    
    if real_length < 1:
        print(length_error)
        real_length = 1

    if real_chans < 1:
        print(chans_error)
        real_chans = 1

    let size_data_obj = sizeof(Data_struct_inner[dataType])

    #Actual object, assigned to result
    result = cast[Data[dataType]](omni_alloc(culong(size_data_obj)))
    
    #Data of the object (the array)
    let 
        length_X_chans     = real_length * real_chans
        size_data_type     = sizeof(dataType)
        total_size_culong  = culong(size_data_type * length_X_chans)
        data               = cast[ArrayPtr[dataType]](omni_alloc0(total_size_culong))

    #Register both the Data object and its data to the automatic memory management
    ugen_auto_mem.registerChild(result)
    ugen_auto_mem.registerChild(data)
    
    #Fill the object layout
    result.data           = data
    result.chans          = real_chans
    result.length         = real_length
    result.length_X_chans = length_X_chans

#This is called by the omni parser
template struct_new*[S : SomeNumber, C : SomeNumber](obj_type : typedesc[Data_struct_inner], length : S = int(1), chans : C = int(1), dataType : typedesc = typedesc[float]) : untyped {.dirty.} =
    struct_new_inner(obj_type, length, chans, dataType, ugen_auto_mem, ugen_call_type)

#This can be used by the user
template new*[S : SomeNumber, C : SomeNumber](obj_type : typedesc[Data_struct_inner], length : S = int(1), chans : C = int(1), dataType : typedesc = typedesc[float]) : untyped {.dirty.} =
    struct_new_inner(obj_type, length, chans, dataType, ugen_auto_mem, ugen_call_type)

proc checkDataValidity*[T](data : Data[T]) : bool =
    when T isnot SomeNumber:
        for i in 0..(data.chans-1):
            for y in 0..(data.length-1):
                let entry = cast[pointer](data[i, y])
                if isNil(entry):
                    print("ERROR: Omni: Not all Data entries have been initialized in the \'init\' block. This can happen if using a Data containing structs, and not having allocated all of the Data entries in \'init\'!")
                    return false
    return true

############
# ITERATOR #
############

iterator items*[T](data : Data[T]) : T {.inline.} =
    for chan in 0..(data.chans-1):
        var i = 0
        while i < data.length:
            yield data[chan, i]
            inc(i)

iterator pairs*[T](data: Data[T]) : tuple[key: int, val : T] {.inline.} =
    for chan in 0..(data.chans-1):
        var i = 0
        while i < data.length:
            yield (i, data[i])
            inc(i)

##########
# GETTER #
##########

proc getter[T](data : Data[T], channel : int = 0, index : int = 0) : T {.inline.} =
    let chans = data.chans
    
    var actual_index : int
    
    if chans == 1:
        actual_index = index
    else:
        actual_index = (index * chans) + channel
    
    if actual_index >= 0 and actual_index < data.length_X_chans:
        return data.data[actual_index]
    
    when T is SomeNumber:
        return T(0)
    else:
        return nil

#1 channel 
proc `[]`*[I : SomeNumber, T](a : Data[T], i : I) : T {.inline.} =
    return a.getter(0, int(i))

#more than 1 channel (i1 == channel, i2 == index)
proc `[]`*[I1 : SomeNumber, I2 : SomeNumber; T](a : Data[T], i1 : I1, i2 : I2) : T {.inline.} =
    return a.getter(int(i1), int(i2))

#cubic interp read (1 channel)
proc read*[I : SomeNumber; T : SomeNumber](data : Data[T], index : I) : float {.inline.} =
    let data_len = data.length
    
    if data_len <= 0:
        return 0.0

    let 
        index_int = int(index)
        index1 : int = index_int mod data_len
        index2 : int = (index_int + 1) mod data_len
        index3 : int = (index_int + 2) mod data_len
        index4 : int = (index_int + 3) mod data_len
        frac : float = float(index) - float(index_int)
    
    return float(cubic_interp(frac, data.getter(0, index1), data.getter(0, index2), data.getter(0, index3), data.getter(0, index4)))

#cubic interp read (more than 1 channel) (i1 == channel, i2 == index)
proc read*[I1 : SomeNumber, I2 : SomeNumber; T : SomeNumber](data : Data[T], chan : I1, index : I2) : float {.inline.} =
    let data_len = data.length
    
    if data_len <= 0:
        return 0.0
    
    let
        chan_int = int(chan)
        index_int = int(index)
        index1 : int = index_int mod data_len
        index2 : int = (index_int + 1) mod data_len
        index3 : int = (index_int + 2) mod data_len
        index4 : int = (index_int + 3) mod data_len
        frac : float = float(index) - float(index_int)
    
    return float(cubic_interp(frac, data.getter(chan_int, index1), data.getter(chan_int, index2), data.getter(chan_int, index3), data.getter(chan_int, index4)))

##########
# SETTER #
##########

proc setter[T, Y](data : Data[T], channel : int = 0, index : int = 0,  x : Y) : void {.inline.} =
    let chans = data.chans
    
    var actual_index : int
    
    if chans == 1:
        actual_index = index
    else:
        actual_index = (index * chans) + channel
    
    if actual_index >= 0 and actual_index < data.length_X_chans:
        when T is SomeNumber and Y is SomeNumber:
            data.data[actual_index] = T(x)
        elif T is Y:
            data.data[actual_index] = x
        else:
            {.fatal: "'" & $T & "': invalid dataType for Data's setter function".}

#1 channel     
proc `[]=`*[I : SomeNumber, T, S](a : Data[T], i : I, x : S) : void {.inline.} =
    a.setter(int(0), int(i), x)

#more than 1 channel (i1 == channel, i2 == index)
proc `[]=`*[I1 : SomeNumber, I2 : SomeNumber; T, S](a : Data[T], i1 : I1, i2 : I2, x : S) : void {.inline.} =
    a.setter(int(i1), int(i2), x)

#########
# INFOS #
#########

proc len*[T](data : Data[T]) : int =
    return data.length

proc size*[T](data : Data[T]) : int =
    return data.length_X_chans

proc chans*[T](data : Data[T]) : int =
    return data.chans