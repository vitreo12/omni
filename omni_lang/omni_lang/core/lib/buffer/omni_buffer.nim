# MIT License
# 
# Copyright (c) 2020-2021 Francesco Cameli
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

import ../auto_mem/omni_auto_mem, ../../lang/omni_call_types

type
    Buffer_inherit* = object of RootObj
        name        : string
        valid_lock  : bool
        length*     : int
        samplerate* : float
        channels*   : int

    #Don't export these, they are just needed here to define some common operations on Buffers
    Buffer = ptr Buffer_inherit
    Buffer_omni_struct_ptr = Buffer

#Allocate a new Buffer
template omni_init_buffer*(name : string) : untyped {.dirty.} =
    Buffer_omni_struct_new(
        buffer_name=name,
        buffer_interface=buffer_interface,
        samplerate=samplerate,
        bufsize=bufsize,
        omni_struct_type=Buffer_omni_struct_ptr, 
        omni_auto_mem=omni_auto_mem, 
        omni_call_type=omni_call_type
    )

#Internal checking for structs. Buffer doesn't allocate more than itself, so just return true.
proc omni_check_datas_validity*(obj : Buffer, samplerate : float, bufsize : int, omni_auto_mem : Omni_AutoMem, omni_call_type : typedesc[Omni_CallType] = Omni_InitCall) : void =
    discard 

#used in omniBufferInterface
proc omni_set_name_buffer*(buffer : Buffer, name : string) : void {.inline.} =
    buffer.name = name

#return buffer's name (used internally)
proc name*(buffer : Buffer) : string {.inline.} =
    return buffer.name

#used in omniBufferInterface
proc omni_set_valid_lock_buffer*(buffer : Buffer, valid_lock : bool) : void {.inline.} =
    buffer.valid_lock = valid_lock

#return buffer's valid_lock (used internally)
proc valid_lock*(buffer : Buffer) : bool {.inline.} =
    return buffer.valid_lock

#short for length
template len*(buffer : Buffer) : untyped =
    buffer.length

#short for channels
template chans*(buffer : Buffer) : untyped =
    buffer.channels
    
#size = chans * length
template size*(buffer : Buffer) : untyped =
    buffer.channels * buffer.length

#1 channel
template `[]`*[I : SomeNumber](buffer : Buffer, i : I) : untyped =
    omni_get_value_buffer(buffer, 0, int(i), omni_call_type)
    
#more than 1 channel (i1 == channel, i2 == index)
template `[]`*[I1 : SomeNumber, I2 : SomeNumber](buffer : Buffer, i1 : I1, i2 : I2) : untyped =
    omni_get_value_buffer(buffer, int(i1), int(i2), omni_call_type)

#1 channel
template `[]=`*[I : SomeNumber, S : SomeNumber](buffer : Buffer, i : I, x : S) : untyped =
    omni_set_value_buffer(buffer, 0, int(i), x, omni_call_type)

#more than 1 channel (i1 == channel, i2 == index)
template `[]=`*[I1 : SomeNumber, I2 : SomeNumber, S : SomeNumber](buffer : Buffer, i1 : I1, i2 : I2, x : S) : untyped =
    omni_set_value_buffer(buffer, int(i1), int(i2), x, omni_call_type)

#interp read
template read*[I : SomeNumber](buffer : Buffer, index : I) : untyped =
    omni_read_value_buffer(buffer, index, omni_call_type)

#interp read
template read*[I1 : SomeNumber, I2 : SomeNumber](buffer : Buffer, chan : I1, index : I2) : untyped =
    omni_read_value_buffer(buffer, chan, index, omni_call_type)
