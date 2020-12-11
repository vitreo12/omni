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

#Have the call here because it can export stuff, needs to be top level
ins 5:
  {440}
  {0.1}
  {0.2}
  {0.3}
  {0.4}

suite "ins: defaults":
  alloc_ins_Nim(5)

  #Check num of inputs
  test "number of inputs":
    check (omni_inputs == 5)

  #Check empty name
  test "input names":
    check (omni_inputs_names_const == "in1,in2,in3,in4,in5")
    check (omni_inputs_names_let == "in1,in2,in3,in4,in5") 

  #Check default values
  test "default values":
    check (omni_inputs_defaults_const == [440.0'f32, 0.1'f32, 0.2'f32, 0.3'f32, 0.4'f32])
    check (omni_inputs_defaults_let   == [440.0'f32, 0.1'f32, 0.2'f32, 0.3'f32, 0.4'f32])

  #Check that the templates exist
  test "templates exist":
    check (declared(in1)); check (declared(in2)); check (declared(in3)); check (declared(in4)); check (declared(in5))
    check (declared(arg1)); check (declared(arg2)); check (declared(arg3)); check (declared(arg4)); check (declared(arg5))

  #Check the values in omni_ins_ptr
  test "templates values":
    check (in1 == 0.75); check (in2 == 0.75); check (in3 == 0.75); check (in4 == 0.75); check (in5 == 0.75)
    check (arg1 == 0.75); check (arg2 == 0.75); check (arg3 == 0.75); check (arg4 == 0.75); check (arg5 == 0.75)

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
    check (cast[cstring](Omni_UGenInputsNames()) == "in1,in2,in3,in4,in5")
    
    let defaultsArray = cast[ptr UncheckedArray[cfloat]](Omni_UGenInputsDefaults())
    check (defaultsArray != nil)
    check (defaultsArray[0] == 440.0'f32)
    check (defaultsArray[1] == 0.1'f32)
    check (defaultsArray[2] == 0.2'f32)
    check (defaultsArray[3] == 0.3'f32)
    check (defaultsArray[4] == 0.4'f32)

  dealloc_ins_Nim(5)
