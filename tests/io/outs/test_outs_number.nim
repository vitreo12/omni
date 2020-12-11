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

#Have the call here because it can export stuff, needs to be top level
outs 5

suite "outs: number":
  #Check num of inputs
  test "number of outputs":
    check (omni_outputs == 5)

  #Check empty name
  test "output names":
    check (omni_outputs_names_const == "out1,out2,out3,out4,out5")
    check (omni_outputs_names_let == "out1,out2,out3,out4,out5") 

  #Check C exported functions
  test "exported C functions":
    check (Omni_UGenOutputs() == int32(5))
    check (cast[cstring](Omni_UGenOutputsNames()) == "out1,out2,out3,out4,out5")
