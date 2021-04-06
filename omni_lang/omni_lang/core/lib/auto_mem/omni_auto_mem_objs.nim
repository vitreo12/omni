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

#Handling of allocation errors
type Omni_JmpBuf* {.importc: "jmp_buf", header: "<setjmp.h>".} = object
proc omni_longjmp*(jmpb: Omni_JmpBuf, retval: cint) {.header: "<setjmp.h>", importc: "longjmp".}
proc omni_setjmp*(jmpb: Omni_JmpBuf): cint {.header: "<setjmp.h>", importc: "setjmp".}

const Omni_AutoMemSize* = 50

type
    C_void_ptr_ptr* = ptr UncheckedArray[pointer] #void**

    #use Omni_AutoMem_struct and not _omni_struct because _omni_struct is 
    #reserved for the REAL omni `struct` handling!
    Omni_AutoMem_struct* = object
        num_allocs* : int
        allocs*     : C_void_ptr_ptr 
        jmp_buf*    : Omni_JmpBuf
    
    Omni_AutoMem* = ptr Omni_AutoMem_struct

