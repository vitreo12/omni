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
# SOFTWARE.

import ../alloc/omni_alloc
import ../auto_mem/omni_auto_mem
import ../print/omni_print
import ../math/omni_math

type
    ArrayPtr[T] = ptr UncheckedArray[T]

    Data_obj[T] = object
        data  : ArrayPtr[T]
        size  : int
        chans : int
        size_X_chans : int

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
proc struct_init_inner*[S : SomeNumber, C : SomeInteger](obj_type : typedesc[Data], size : S = int(1), chans : C = int(1), dataType : typedesc = typedesc[float], ugen_auto_mem : ptr OmniAutoMem) : Data[dataType]  {.inline.} =
    
    #error out if trying to instantiate any dataType that is not a Number
    when dataType isnot SomeNumber: 
        {.fatal: "Data's dataType must be SomeNumber".}

    var 
        real_size  = int(size)
        real_chans = int(chans)
    
    if real_size < 1:
        print(size_error)
        real_size = 1

    if real_chans < 1:
        print(chans_error)
        real_chans = 1

    let size_data_obj = sizeof(Data_obj[dataType])

    #Actual object, assigned to result
    result = cast[Data[dataType]](omni_alloc(culong(size_data_obj)))
    
    #Data of the object (the array)
    let 
        size_X_chans           = real_size * real_chans
        size_X_chans_uint      = uint(size_X_chans)
        size_data_type_uint    = uint(sizeof(dataType))
        total_size_culong      = culong(size_data_type_uint * size_X_chans_uint)
        data                   = cast[ArrayPtr[dataType]](omni_alloc0(total_size_culong))

    #Register both the Data object and its data to the automatic memory management
    ugen_auto_mem.registerChild(result)
    ugen_auto_mem.registerChild(data)
    
    #Fill the object layout
    result.data         = data
    result.chans        = real_chans
    result.size         = real_size
    result.size_X_chans = size_X_chans

template new*[S : SomeNumber, C : SomeInteger](obj_type : typedesc[Data], size : S = uint(1), chans : C = uint(1), dataType : typedesc = typedesc[float]) : untyped {.dirty.} =
    struct_init_inner(Data, size, chans, dataType, ugen_auto_mem)   

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
    
    if actual_index >= 0 and actual_index < data.size_X_chans:
        return data.data[actual_index]
    
    return T(0)

#1 channel 
proc `[]`*[I : SomeNumber, T](a : Data[T], i : I) : T {.inline.} =
    return a.getter(0, int(i))

#more than 1 channel (i1 == channel, i2 == index)
proc `[]`*[I1 : SomeNumber, I2 : SomeNumber; T](a : Data[T], i1 : I1, i2 : I2) : T {.inline.} =
    return a.getter(int(i1), int(i2))

#linear interp read (1 channel)
proc read*[I : SomeNumber; T](data : Data[T], index : I) : float {.inline.} =
    let data_len = data.size
    
    if data_len <= 0:
        return 0.0

    let 
        index_int = int(index)
        index1 : int = index_int mod data_len
        index2 : int = (index1 + 1) mod data_len
        frac : float = float(index) - float(index_int)
    
    return linear_interp(frac, data.getter(0, index1), data.getter(0, index2))

#linear interp read (more than 1 channel) (i1 == channel, i2 == index)
proc read*[I1 : SomeNumber, I2 : SomeNumber; T](data : Data[T], chan : I1, index : I2) : float {.inline.} =
    let data_len = data.size
    
    if data_len <= 0:
        return 0.0
    
    let
        chan_int = int(chan)
        index_int = int(index)
        index1 : int = index_int mod data_len
        index2 : int = (index1 + 1) mod data_len
        frac : float = float(index) - float(index_int)
    
    return linear_interp(frac, data.getter(chan_int, index1), data.getter(chan_int, index2))

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
    
    if actual_index >= 0 and actual_index < data.size_X_chans:
        data.data[actual_index] = T(x)

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
    return data.size

proc size*[T](data : Data[T]) : int =
    return data.size_X_chans

proc chans*[T](data : Data[T]) : int =
    return data.chans