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
when declared(Buffer):
  buffers 2:
      buf1 "something"
      buf2 "somethingElse"

  suite "buffers":
    test "number of buffers":
      check (omni_buffers == 2)

    test "input names":
      check (omni_buffers_names_const == "buf1,buf2")

    test "default values":
      check (omni_buffers_defaults_const == ["something", "somethingElse"])
    
    test "exported C functions":
      check (Omni_UGenBuffers() == int32(2))
      check (cast[cstring](Omni_UGenBuffersNames()) == "buf1,buf2")
      check (cast[cstring](Omni_UGenBuffersDefaults()) == "something,somethingElse")