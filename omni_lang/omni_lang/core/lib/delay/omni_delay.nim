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
import ../../lang/omni_types
import ../alloc/omni_alloc
import ../data/omni_data
import ../auto_mem/omni_auto_mem
import ../math/omni_math

type
    Delay_struct_inner* = object
        mask  : int
        phase : int
        data  : Data[signal]

    Delay* = ptr Delay_struct_inner

proc struct_new_inner*[S : SomeNumber](obj_type : typedesc[Delay_struct_inner], size : S = uint(1), ugen_auto_mem : ptr OmniAutoMem, ugen_call_type : typedesc[CallType] = InitCall) : Delay {.inline.} =
    #Trying to allocate in perform block!
    when ugen_call_type is PerformCall:
        {.fatal: "attempting to allocate memory in the 'perform' or 'sample' blocks for 'struct Delay'".}

    #Allocate obj
    result = cast[Delay](omni_alloc(culong(sizeof(Delay_struct_inner))))

    #Allocate data
    let 
        delay_length = int(nextPowerOfTwo(int(size)))
        data  = Data.struct_new_inner(delay_length, dataType=signal, ugen_auto_mem=ugen_auto_mem, ugen_call_type=ugen_call_type)
        mask  = int(delay_length - 1)

    #Register obj (data has already been registered in Data.struct_new_inner)
    ugen_auto_mem.registerChild(result)

    #Assign values
    result.mask = mask
    result.phase = 0
    result.data = data

template struct_new*[S : SomeNumber](obj_type : typedesc[Delay_struct_inner], size : S = uint(1)) : untyped {.dirty.} =
    struct_new_inner(obj_type, size, ugen_auto_mem, ugen_call_type)

template new*[S : SomeNumber](obj_type : typedesc[Delay_struct_inner], size : S = uint(1)) : untyped {.dirty.} =
    struct_new_inner(obj_type, size, ugen_auto_mem, ugen_call_type)

proc checkValidity*(obj : Delay, ugen_auto_buffer : ptr OmniAutoMem) : bool =
    return true

#Read proc (uses cubic interp)
proc read*[Y : SomeNumber](delay : Delay, delay_time : Y) : float {.inline.} =
    let 
        float_delay_time = float(delay_time)
        frac : float = float_delay_time - delay_time
        index  = (delay.phase - int(delay_time))
        index1 = index and delay.mask
        index2 = (index + 1) and delay.mask
        index3 = (index + 2) and delay.mask
        index4 = (index + 3) and delay.mask

    return float(cubic_interp(frac, delay.data[index1], delay.data[index2], delay.data[index3], delay.data[index4]))

#Write proc
proc write*[Y : SomeNumber](delay : Delay, val : Y) : void {.inline.} =
    delay.data[delay.phase] = float(val)
    delay.phase = (delay.phase + 1) and delay.mask