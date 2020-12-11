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
import ../alloc/omni_alloc
import ../data/omni_data
import ../auto_mem/omni_auto_mem
import ../math/omni_math

type
    Delay_omni_struct_inner* = object
        mask  : int
        phase : int
        data  : Data[float]

    Delay* = ptr Delay_omni_struct_inner

    Delay_omni_struct_export* = Delay

proc Delay_omni_struct_new_inner*[S : SomeNumber](size : S = int(0), samplerate : float, struct_type : typedesc[Delay_omni_struct_export], omni_auto_mem : ptr Omni_AutoMem, omni_call_type : typedesc[Omni_CallType] = Omni_InitCall) : Delay {.inline.} =
    #Trying to allocate in perform block!
    when omni_call_type is Omni_PerformCall:
        {.fatal: "Delay: attempting to allocate memory in the 'perform' or 'sample' blocks.".}

    #If size <= 0 (default), delay length will be samplerate
    var actual_size = int(size)
    if actual_size <= 0:
        actual_size = int(samplerate)

    #Allocate obj
    result = cast[Delay](omni_alloc(culong(sizeof(Delay_omni_struct_inner))))

    #Allocate data
    let 
        delay_length = int(nextPowerOfTwo(actual_size))
        data  = Data_omni_struct_new_inner(delay_length, G1=float, struct_type=Data_omni_struct_export, omni_auto_mem=omni_auto_mem, omni_call_type=omni_call_type)
        mask  = int(delay_length - 1)

    #Register obj (data has already been registered in Data.omni_struct_new_inner)
    omni_auto_mem.omni_auto_mem_register_child(result)

    #Assign values
    result.mask = mask
    result.phase = 0
    result.data = data

#This is probably useless and can be removed :)
proc omni_check_struct_validity*(obj : Delay #[, ugen_auto_buffer : ptr Omni_AutoMem]#) : bool =
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