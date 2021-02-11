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

template alloc_ins_Nim*(n : int) : untyped =
  let 
    ins_ptr_64_void {.inject.} = system.alloc(sizeof(CDoublePtr) * n)
    ins_ptr_32_void {.inject.} = system.alloc(sizeof(CFloatPtr) * n)
    ins_ptr_64 {.inject.} = cast[ptr ptr cdouble](ins_ptr_64_void)
    ins_ptr_32 {.inject.} = cast[ptr ptr cfloat](ins_ptr_32_void)
    ins_Nim_64 {.inject.} = cast[CDoublePtrPtr](ins_ptr_64_void)
    ins_Nim_32 {.inject.} = cast[CFloatPtrPtr](ins_ptr_32_void)

    test_bufsize {.inject.} = 1 
    test_samplerate {.inject.} = 48000.0

  for i in 0..(n-1):
    ins_Nim_64[i] = cast[CDoublePtr](system.alloc(sizeof(cdouble) * test_bufsize))
    ins_Nim_32[i] = cast[CFloatPtr](system.alloc(sizeof(cfloat) * test_bufsize))

template dealloc_ins_Nim*(n : int) : untyped =
  for i in 0..(n-1):
    system.dealloc(cast[pointer](ins_Nim_64[i]))
    system.dealloc(cast[pointer](ins_Nim_32[i]))
  system.dealloc(ins_ptr_64_void)
  system.dealloc(ins_ptr_32_void)
