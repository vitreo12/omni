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

template declare_globals*() : untyped {.dirty.} =
    when not declared(bufsize):
        let bufsize {.inject.} : int = 0

    when not declared(samplerate):  
        let samplerate {.inject.} : float = 0.0
    
    when not declared(buffer_interface):
        let buffer_interface {.inject.} : pointer = nil
    
    when not declared(ugen_auto_mem):
        let ugen_auto_mem {.inject.} : ptr OmniAutoMem = nil

    when not declared(ugen_auto_buffer):
        let ugen_auto_buffer {.inject.} : ptr OmniAutoMem = nil

    when not declared(ugen_call_type):
        var ugen_call_type {.inject, noinit.} : typedesc[CallType]

    when not declared(ins_Nim):
        let ins_Nim {.inject.} : CFloatPtrPtr = cast[CFloatPtrPtr](0)