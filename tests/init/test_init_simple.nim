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

import unittest
import ../../omni_lang/omni_lang
import ../utils/init_utils
#import macros

#expandMacros:
init:
  a float
  b = 1.0
  c = 2 
  d int = 3
  a = 4.0
  CONST1 = 5.0
  CONST2 = 6

suite "init: functions and templates exist":
  test "perform_build_names_table":
    check (declared(perform_build_names_table))

  test "generateTemplatesForPerformVarDeclarations":
    check (declared(generateTemplatesForPerformVarDeclarations))
    generateTemplatesForPerformVarDeclarations()
    check (declared(a))
    check (declared(b))
    check (declared(c))
    check (declared(CONST1))
    check (declared(CONST2))

  test "UGen have correct fields":
    check (declared(UGen))
    check (typeof(UGen.a_var) is float)
    check (typeof(UGen.b_var) is float)
    check (typeof(UGen.c_var) is float)
    check (typeof(UGen.d_var) is int)
    check (typeof(UGen.CONST1_let) is float)
    check (typeof(UGen.CONST2_let) is int)
    check (typeof(UGen.is_initialized_let) is bool)
    check (typeof(UGen.samplerate_let) is float)
    check (typeof(UGen.ugen_auto_mem_let) is ptr OmniAutoMem)
    check (typeof(UGen.ugen_auto_buffer_let) is ptr OmniAutoMem)

  test "Omni_UGenAlloc exists":
    check (declared(Omni_UGenAlloc))
  
  test "Omni_UGenInit32 exists":
    check (declared(Omni_UGenInit32))

  test "Omni_UGenInit64 exists":
    check (declared(Omni_UGenInit64))
  
  test "Omni_UGenAllocInit32 exists":
    check (declared(Omni_UGenAllocInit32))

  test "Omni_UGenAllocInit64 exists":
    check (declared(Omni_UGenAllocInit64))

suite "init: Omni_UGenAlloc + Omni_UGenInit64":
  #After check of Omni_UGenAlloc, allocate one dummy ugen
  let 
    ugen_ptr_64 = Omni_UGenAlloc()
    ugen_64 = cast[ptr UGen](ugen_ptr_64)

  test "is_initialized is false":
    check (ugen_64.is_initialized_let == false)

  test "ugen_auto_mem is nil":
    check (ugen_64.ugen_auto_mem_let == nil)

  test "ugen_auto_buffer is nil":
    check (ugen_64.ugen_auto_buffer_let == nil)

  alloc_ins_Nim(1)

  #Init the ugen
  let init_ugen = Omni_UGenInit64(ugen_ptr_64, ins_ptr_64, cint(test_bufsize), cdouble(test_samplerate), nil)

  test "ugen init":
    check (init_ugen == 1)

  test "ugen is_initialized true":
    check (ugen_64.is_initialized_let == true)

  test "ugen_auto_mem is not nil":
    check (ugen_64.ugen_auto_mem_let != nil)

  test "ugen_auto_buffer is not nil":
    check (ugen_64.ugen_auto_buffer_let != nil)

  test "ugen's field values":
    check (ugen_64.a_var == 4.0)
    check (ugen_64.b_var == 1.0)
    check (ugen_64.c_var == 2.0)
    check (ugen_64.d_var == 3)
    check (ugen_64.CONST1_let == 5.0)
    check (ugen_64.CONST2_let == 6)
    check (ugen_64.samplerate_let == test_samplerate)

  dealloc_ins_Nim(1)

  #How to test Omni_UGenFree ?
  Omni_UGenFree(ugen_ptr_64)

suite "init: Omni_UGenAlloc + Omni_UGenInit32":
  #After check of Omni_UGenAlloc, allocate one dummy ugen
  let 
    ugen_ptr_32 = Omni_UGenAlloc()
    ugen_32 = cast[ptr UGen](ugen_ptr_32)

  test "is_initialized is false":
    check (ugen_32.is_initialized_let == false)

  test "ugen_auto_mem is nil":
    check (ugen_32.ugen_auto_mem_let == nil)

  test "ugen_auto_buffer is nil":
    check (ugen_32.ugen_auto_buffer_let == nil)

  alloc_ins_Nim(1)

  #Init the ugen
  let init_ugen = Omni_UGenInit32(ugen_ptr_32, ins_ptr_32, cint(test_bufsize), cdouble(test_samplerate), nil)

  test "ugen init":
    check (init_ugen == 1)

  test "ugen is_initialized true":
    check (ugen_32.is_initialized_let == true)

  test "ugen_auto_mem is not nil":
    check (ugen_32.ugen_auto_mem_let != nil)

  test "ugen_auto_buffer is not nil":
    check (ugen_32.ugen_auto_buffer_let != nil)

  test "ugen's field values":
    check (ugen_32.a_var == 4.0)
    check (ugen_32.b_var == 1.0)
    check (ugen_32.c_var == 2.0)
    check (ugen_32.d_var == 3)
    check (ugen_32.CONST1_let == 5.0)
    check (ugen_32.CONST2_let == 6)
    check (ugen_32.samplerate_let == test_samplerate)

  dealloc_ins_Nim(1)

  #How to test Omni_UGenFree ?
  Omni_UGenFree(ugen_ptr_32)

suite "init: Omni_UGenAllocInit64":
  
  alloc_ins_Nim(1)
  
  let 
    ugen_ptr_64 = Omni_UGenAllocInit64(ins_ptr_64, cint(test_bufsize), cdouble(test_samplerate), nil)
    ugen_64 = cast[ptr UGen](ugen_ptr_64)

  test "ugen init":
    check (ugen_ptr_64 != nil)

  test "ugen is_initialized true":
    check (ugen_64.is_initialized_let == true)

  test "ugen_auto_mem is not nil":
    check (ugen_64.ugen_auto_mem_let != nil)

  test "ugen_auto_buffer is not nil":
    check (ugen_64.ugen_auto_buffer_let != nil)

  test "ugen's field values":
    check (ugen_64.a_var == 4.0)
    check (ugen_64.b_var == 1.0)
    check (ugen_64.c_var == 2.0)
    check (ugen_64.d_var == 3)
    check (ugen_64.CONST1_let == 5.0)
    check (ugen_64.CONST2_let == 6)
    check (ugen_64.samplerate_let == test_samplerate)

  dealloc_ins_Nim(1)

  #How to test Omni_UGenFree ?
  Omni_UGenFree(ugen_ptr_64)

suite "init: Omni_UGenAllocInit32":
  
  alloc_ins_Nim(1)
  
  let 
    ugen_ptr_32 = Omni_UGenAllocInit32(ins_ptr_32, cint(test_bufsize), cdouble(test_samplerate), nil)
    ugen_32 = cast[ptr UGen](ugen_ptr_32)

  test "ugen init":
    check (ugen_ptr_32 != nil)

  test "ugen is_initialized true":
    check (ugen_32.is_initialized_let == true)

  test "ugen_auto_mem is not nil":
    check (ugen_32.ugen_auto_mem_let != nil)

  test "ugen_auto_buffer is not nil":
    check (ugen_32.ugen_auto_buffer_let != nil)

  test "ugen's field values":
    check (ugen_32.a_var == 4.0)
    check (ugen_32.b_var == 1.0)
    check (ugen_32.c_var == 2.0)
    check (ugen_32.d_var == 3)
    check (ugen_32.CONST1_let == 5.0)
    check (ugen_32.CONST2_let == 6)
    check (ugen_32.samplerate_let == test_samplerate)

  dealloc_ins_Nim(1)

  #How to test Omni_UGenFree ?
  Omni_UGenFree(ugen_ptr_32)

