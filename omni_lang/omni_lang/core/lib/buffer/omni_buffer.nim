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

type
    Buffer_inherit* = object of RootObj
        name*       : cstring
        valid*      : bool

    #Don't export these, they are just needed here to define some common operations on Buffers
    Buffer = ptr Buffer_inherit
    Buffer_omni_struct_ptr = Buffer

#Allocate a new Buffer
template omni_init_buffer*() : untyped {.dirty.} =
    Buffer_omni_struct_new(
        buffer_interface=buffer_interface,
        omni_struct_type=Buffer_omni_struct_ptr, 
        omni_auto_mem=omni_auto_mem, 
        omni_call_type=omni_call_type
    )

#1 channel
template `[]`*[I : SomeNumber](buffer : Buffer, i : I) : untyped {.dirty.} =
    omni_get_value_buffer(buffer, 0, int(i), omni_call_type)
    
#more than 1 channel (i1 == channel, i2 == index)
template `[]`*[I1 : SomeNumber, I2 : SomeNumber](buffer : Buffer, i1 : I1, i2 : I2) : untyped {.dirty.} =
    omni_get_value_buffer(buffer, int(i1), int(i2), omni_call_type)

#1 channel
template `[]=`*[I : SomeNumber, S : SomeNumber](buffer : Buffer, i : I, x : S) : untyped {.dirty.} =
    omni_set_value_buffer(buffer, 0, int(i), x, omni_call_type)

#more than 1 channel (i1 == channel, i2 == index)
template `[]=`*[I1 : SomeNumber, I2 : SomeNumber, S : SomeNumber](buffer : Buffer, i1 : I1, i2 : I2, x : S) : untyped {.dirty.} =
    omni_set_value_buffer(buffer, int(i1), int(i2), x, omni_call_type)

#interp read
template read*[I : SomeNumber](buffer : Buffer, index : I) : untyped {.dirty.} =
    omni_read_value_buffer(buffer, index, omni_call_type)

#interp read
template read*[I1 : SomeNumber, I2 : SomeNumber](buffer : Buffer, chan : I1, index : I2) : untyped {.dirty.} =
    omni_read_value_buffer(buffer, chan, index, omni_call_type)

#length
template length*(buffer : Buffer) : untyped {.dirty.} =
    omni_get_length_buffer(buffer, omni_call_type)

template len*(buffer : Buffer) : untyped {.dirty.} =
    length(buffer)

#samplerate
template samplerate*(buffer : Buffer) : untyped {.dirty.} =
    omni_get_samplerate_buffer(buffer, omni_call_type)

#channels
template channels*(buffer : Buffer) : untyped {.dirty.} =
    omni_get_channels_buffer(buffer, omni_call_type)

template chans*(buffer : Buffer) : untyped {.dirty.} =
    channels(buffer)
    
#Chans * length = size
template size*(buffer : Buffer) : untyped =
    channels(buffer) * length(buffer)

#Internal checking for structs. It works fine without redefining it for every omniBufferInterface!
proc omni_check_struct_validity*(obj : Buffer) : bool =
    return true