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
import ../../../omni_lang/omni_lang
import ../../utils/ins_utils

#Have the call here cause it also exports stuff, which can only happen at top level
ins 5:
  "freq"  {440, -20000, 20000}
  "phase" {0.1, 0, 1}
  "amp"   {0.2, 0.0, 1.0}
  "mul"   {0.3, 0.5, 2.35}
  "add"   {0.4, -0.1, 10000}

suite "ins: names + defaults + min/max":
  alloc_ins_Nim(5)

  #Check num of inputs
  test "number of inputs":
    check (omni_inputs == 5)

  #Check empty name
  test "input names":
    check (omni_inputs_names_const == "freq,phase,amp,mul,add")

  #Check default values
  test "default values":
    check (omni_inputs_defaults_const == [440.0'f32, 0.1'f32, 0.2'f32, 0.3'f32, 0.4'f32])

  #Check min values
  test "min/max values":
    check (in1_omni_min == -20000.0); check (in2_omni_min == 0.0); check (in3_omni_min == 0.0); check (in4_omni_min == 0.5); check (in5_omni_min == -0.1)
    check (in1_omni_max == 20000.0); check (in2_omni_max == 1.0); check (in3_omni_max == 1.0); check (in4_omni_max == 2.35); check (in5_omni_max == 10000.0)

  #Check min_max functions
  test "min_max functions":
    check (in1_omni_min_max(-30000.0) == -20000.0); 
    check (in1_omni_min_max(30000.0) == 20000.0)
    check (in2_omni_min_max(-0.2) == 0.0); 
    check (in2_omni_min_max(1.1) == 1.0)
    check (in4_omni_min_max(3.0) == 2.35)
    check (in5_omni_min_max(-0.11) == -0.1);

  #Check that the templates exist
  test "templates exist":
    check (declared(in1)); check (declared(in2)); check (declared(in3)); check (declared(in4)); check (declared(in5))

  #Check the values in omni_ins_ptr
  test "templates values":
    check (in1 == 0.75); check (in2 == 0.75); check (in3 == 0.75); check (in4 == 0.75); check (in5 == 0.75)
    
  #Check omni_get_dynamic_input
  test "omni_get_dynamic_input":
    check (declared(omni_get_dynamic_input))
    check (omni_get_dynamic_input(omni_ins_ptr, 0, 0) == 0.75)
    check (omni_get_dynamic_input(omni_ins_ptr, 1, 0) == 0.75)
    check (omni_get_dynamic_input(omni_ins_ptr, 2, 0) == 0.75)
    check (omni_get_dynamic_input(omni_ins_ptr, 3, 0) == 0.75)
    check (omni_get_dynamic_input(omni_ins_ptr, 4, 0) == 0.75)
  
  #Check C exported functions
  test "exported C functions":
    check (Omni_UGenInputs() == int32(5))
    check (cast[cstring](Omni_UGenInputsNames()) == "freq,phase,amp,mul,add")
    
    let defaultsArray = cast[ptr UncheckedArray[cfloat]](Omni_UGenInputsDefaults())
    check (defaultsArray != nil)
    check (defaultsArray[0] == 440.0'f32)
    check (defaultsArray[1] == 0.1'f32)
    check (defaultsArray[2] == 0.2'f32)
    check (defaultsArray[3] == 0.3'f32)
    check (defaultsArray[4] == 0.4'f32)

  dealloc_ins_Nim(5)
