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

let omni_invalid_idents* {.compileTime.} = [
    "omni_ugen", "Omni_UGen", "Data", "Delay", "Buffer"
]

let omni_invalid_ends_with* {.compileTime.} = [
    "omni_def_export", "omni_def_dummy",
    "omni_module_inner",
    "omni_struct_inner", "omni_struct_new", "omni_struct_export"
]

let omni_invalid_variable_names* {.compileTime.} = [
    "omni_ugen", "Omni_UGen",
    "ins", "inputs",
    "outs", "outputs",
    "params",
    "init", "initialize", "initialise", "build",
    "perform", "sample",
    "sig", "sig32", "sig64",
    "signal", "signal32", "signal64",
    "Data", "Buffer", "Delay"
]