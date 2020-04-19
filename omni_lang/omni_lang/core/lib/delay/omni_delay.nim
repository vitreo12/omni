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
import ../data/omni_data
import ../auto_mem/omni_auto_mem
import ../math/omni_math

type
    Delay_obj[T] = object
        mask  : int
        phase : int
        data  : Data[T]

    Delay*[T] = ptr Delay_obj[T]

proc struct_init_inner*[S : SomeNumber](obj_type : typedesc[Delay], size : S = uint(1), dataType : typedesc = typedesc[float], ugen_auto_mem : ptr OmniAutoMem) : Delay[dataType] {.inline.} =
    #error out if trying to instantiate any dataType that is not a Number
    when dataType isnot SomeNumber: 
        {.fatal: "Delay's dataType must be SomeNumber".}

    #Allocate obj
    result = cast[Delay[dataType]](omni_alloc(culong(sizeof(Delay_obj[dataType]))))

    #Allocate data
    let 
        delay_length = int(nextPowerOfTwo(int(size)))
        data  = Data.struct_init_inner(delay_length, dataType=dataType, ugen_auto_mem=ugen_auto_mem)
        mask  = int(delay_length - 1)

    #Register obj (data has already been registered in Data.struct_init_inner)
    ugen_auto_mem.registerChild(result)

    #Assign values
    result.mask = mask
    result.phase = 0
    result.data = data

template new*[S : SomeNumber](obj_type : typedesc[Delay], size : S = uint(1), dataType : typedesc = typedesc[float]) : untyped {.dirty.} =
    struct_init_inner(Delay, size, dataType, ugen_auto_mem)

#Read proc
proc read*[T : SomeNumber, Y : SomeNumber](delay : Delay[T], delay_time : Y) : T {.inline.} =
    let 
        float_delay_time = float(delay_time)
        frac : float = float_delay_time - delay_time
        index  = (delay.phase - int(delay_time))
        index1 = index and delay.mask
        index2 = (index + 1) and delay.mask

    return linear_interp(frac, delay.data[index1], delay.data[index2])

#Write proc
proc write*[T : SomeNumber, Y : SomeNumber](delay : Delay[T], val : Y) : void {.inline.} =
    delay.data[delay.phase] = T(val)
    delay.phase = (delay.phase + 1) and delay.mask