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

import ../../lang/omni_call_types
import ../auto_mem/omni_auto_mem
import ../math/omni_math

type
    #Inherit from this
    Buffer_inherit* = object of RootObj
        input_num*  : int      
        length*     : int
        size*       : int
        chans*      : int
        samplerate* : float

    #Define this
    Buffer* = ptr Buffer_inherit

    #Define this
    Buffer_struct_export* = Buffer

###################
# Procs to define #
###################

#Init buffer
proc Buffer_struct_new_inner*[S : SomeInteger](input_num : S, buffer_interface : pointer, obj_type : typedesc[Buffer_struct_export], ugen_auto_mem : ptr OmniAutoMem, ugen_call_type : typedesc[CallType] = InitCall) : Buffer {.inline.} =
    {.fatal: "No wrapper defined for `Buffer`.".}

#Get buffer if in
proc get_buffer*(buffer : Buffer, input_val : float) : bool {.inline.} =
    return false

#Get buffer if param
proc get_buffer_param*(buffer : Buffer, input_val : float) : bool {.inline.} =
    return false

#Unlock buffer if multithread
when defined(multithreadBuffers):
    proc unlock_buffer*(buffer : Buffer) : void {.inline.} =
        discard

#Get value from buffer
proc getter*(buffer : Buffer, channel : int = 0, index : int = 0, ugen_call_type : typedesc[CallType] = InitCall) : float {.inline.} =
    return 0.0

#Set value in buffer
proc setter*[Y : SomeNumber](buffer : Buffer, channel : int = 0, index : int = 0, x : Y, ugen_call_type : typedesc[CallType] = InitCall) : void {.inline.} =
    discard

#######################
# Procs not to define #
#######################

#1 channel
template `[]`*[I : SomeNumber](a : Buffer, i : I) : untyped {.dirty.} =
    getter(a, 0, int(i), ugen_call_type)

#more than 1 channel (i1 == channel, i2 == index)
template `[]`*[I1 : SomeNumber, I2 : SomeNumber](a : Buffer, i1 : I1, i2 : I2) : untyped {.dirty.} =
    getter(a, int(i1), int(i2), ugen_call_type)

#1 channel
template `[]=`*[I : SomeNumber, S : SomeNumber](a : Buffer, i : I, x : S) : untyped {.dirty.} =
    setter(a, 0, int(i), x, ugen_call_type)

#more than 1 channel (i1 == channel, i2 == index)
template `[]=`*[I1 : SomeNumber, I2 : SomeNumber, S : SomeNumber](a : Buffer, i1 : I1, i2 : I2, x : S) : untyped {.dirty.} =
    setter(a, int(i1), int(i2), x, ugen_call_type)

#linear interp read (1 channel)
proc read_inner*[I : SomeNumber](buffer : Buffer, index : I, ugen_call_type : typedesc[CallType] = InitCall) : float {.inline.} =
    when ugen_call_type is InitCall:
        {.fatal: "`Buffers` can only be accessed in the `perform` / `sample` blocks".}

    let buf_len = buffer.length
    
    if buf_len <= 0:
        return 0.0

    let
        index_int = int(index)
        index1 : int = index_int mod buf_len
        index2 : int = (index1 + 1) mod buf_len
        frac : float  = float(index) - float(index_int)
    
    return float(linear_interp(frac, getter(buffer, 0, index1, ugen_call_type), getter(buffer, 0, index2, ugen_call_type)))

#linear interp read (more than 1 channel) (i1 == channel, i2 == index)
proc read_inner*[I1 : SomeNumber, I2 : SomeNumber](buffer : Buffer, chan : I1, index : I2, ugen_call_type : typedesc[CallType] = InitCall) : float {.inline.} =
    when ugen_call_type is InitCall:
        {.fatal: "`Buffers` can only be accessed in the `perform` / `sample` blocks".}

    let buf_len = buffer.length

    if buf_len <= 0:
        return 0.0
    
    let 
        chan_int = int(chan)
        index_int = int(index)
        index1 : int = index_int mod buf_len
        index2 : int = (index1 + 1) mod buf_len
        frac : float  = float(index) - float(index_int)
    
    return float(linear_interp(frac, getter(buffer, chan_int, index1, ugen_call_type), getter(buffer, chan_int, index2, ugen_call_type)))

#interp read
template read*[I : SomeNumber](buffer : Buffer, index : I) : untyped {.dirty.} =
    read_inner(buffer, index, ugen_call_type)

#interp read
template read*[I1 : SomeNumber, I2 : SomeNumber](buffer : Buffer, chan : I1, index : I2) : untyped {.dirty.} =
    read_inner(buffer, chan, index, ugen_call_type)

#Alias for length
proc len*(buffer : Buffer) : int {.inline.} =
    return buffer.length

#Internal checking for structs
proc checkValidity*(obj : Buffer, ugen_auto_buffer : ptr OmniAutoMem) : bool =
    ugen_auto_buffer.registerChild(cast[pointer](obj))
    return true