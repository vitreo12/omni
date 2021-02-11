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

import unittest
import ../../omni_lang/omni_lang
import ../utils/init_utils

init:
  a float = 0.0
  b = 1.0
  c = 2 
  d int = 3
  a = 4.0
  CONST1 = 5.0
  CONST2 int = 6

suite "init: functions and templates exist":
  test "omni_generate_templates_for_perform_var_declarations":
    check (declared(omni_generate_templates_for_perform_var_declarations))
    omni_generate_templates_for_perform_var_declarations()
    check (declared(a))
    check (declared(b))
    check (declared(c))

  test "Omni_UGen have correct fields":
    check (declared(Omni_UGen))
    check (typeof(Omni_UGen.a_var) is float)
    check (typeof(Omni_UGen.b_var) is float)
    check (typeof(Omni_UGen.c_var) is float)
    check (typeof(Omni_UGen.d_var) is int)
    check (typeof(Omni_UGen.CONST1_let) is float)
    check (typeof(Omni_UGen.CONST2_let) is int)
    check (typeof(Omni_UGen.samplerate_let) is float)
    check (typeof(Omni_UGen.omni_auto_mem) is Omni_AutoMem)
    
  test "Omni_UGenAlloc exists":
    check (declared(Omni_UGenAlloc))
  
  test "Omni_UGenInit exists":
    check (declared(Omni_UGenInit))
  
suite "init: Omni_UGenAlloc + Omni_UGenInit":
  #After check of Omni_UGenAlloc, allocate one dummy omni_ugen
  let 
    ugen_ptr = Omni_UGenAlloc()
    ugen = cast[Omni_UGen](ugen_ptr)

  test "omni_auto_mem is nil":
    check (ugen.omni_auto_mem == nil)

  alloc_ins_Nim(1)

  #Init the omni_ugen
  let init_ugen = Omni_UGenInit(ugen_ptr, cint(test_bufsize), cdouble(test_samplerate), nil)

  test "omni_ugen init":
    check (init_ugen == 1)

  test "omni_auto_mem is not nil":
    check (ugen.omni_auto_mem != nil)

  test "omni_ugen's field values":
    check (ugen.a_var == 4.0)
    check (ugen.b_var == 1.0)
    check (ugen.c_var == 2.0)
    check (ugen.d_var == 3)
    check (ugen.CONST1_let == 5.0)
    check (ugen.CONST2_let == 6)
    check (ugen.samplerate_let == test_samplerate)

  dealloc_ins_Nim(1)

  #How to test Omni_UGenFree ?
  Omni_UGenFree(ugen_ptr)