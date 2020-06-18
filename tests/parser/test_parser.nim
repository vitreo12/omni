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
import ../utils/parser_utils

struct Test1:
  a; b; c

struct Test2:
  test1 Test1

struct Test3:
  data Data

#Dummy vars. Only checking correct parsing here
var 
  ugen_auto_mem = cast[ptr OmniAutoMem](0) 
  ugen_call_type : typedesc[InitCall]

suite "parser: variable declarations":
  test "simple declarations":    
    let test = compareOmniNim:
      omni:
        a = 0 
        b = 1.0
        c float = 2.0
        d float
        d = 3
        CONST = 4
      nim:
        var a = 0
        var b = 1.0
        var c : float = 2.0
        var d : float
        d = typeof(d)(3)
        let CONST = 4

    check test

suite "parser: struct allocs":
  test "simple struct":
    let test = compareOmniNim:
      omni:
        a = Test1()
      nim:
        let a = struct_new_inner(Test1, 0, 0, 0, ugen_auto_mem, ugen_call_type) 

    check test

  test "double struct":
    let test = compareOmniNim:
      omni:
        a = Test2(Test1())
        b = Test1()
        c = Test2(b)
      nim:
        let a = struct_new_inner(Test2, struct_new_inner(Test1, 0, 0, 0, ugen_auto_mem, ugen_call_type), ugen_auto_mem, ugen_call_type)
        let b = struct_new_inner(Test1, 0, 0, 0, ugen_auto_mem, ugen_call_type)
        let c = struct_new_inner(Test2, b, ugen_auto_mem, ugen_call_type)

    check test

  test "simple struct with Data":
    let test = compareOmniNim:
      omni:
        data = Data(1)
        a = Test3(data) 
      nim:
        let data = struct_new_inner(Data, 1, int(1), typedesc[float], ugen_auto_mem, ugen_call_type)
        let a = struct_new_inner(Test3, data, ugen_auto_mem, ugen_call_type)

    check test
