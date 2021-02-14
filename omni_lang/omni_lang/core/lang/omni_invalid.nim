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

let omni_invalid_idents* {.compileTime.} = [
    "omni_ugen", "Omni_UGen", 
    "omni_auto_mem", "Omni_AutoMem",
    "Omni_Param",
    "AtomicFlag",
    "omni_params_lock", "omni_buffers_lock",
    "Data", "Delay", "Buffer"
]

let omni_invalid_ends_with* {.compileTime.} = [
    "omni_min_max",
    "omni_param",
    "omni_buffer",
    "omni_def", "omni_def_export", "omni_def_dummy",
    "omni_module",
    "omni_struct", "omni_struct_new", "omni_struct_ptr"
]

let omni_invalid_variable_names* {.compileTime.} = [
    "omni_ugen",
    "omni_auto_mem", "omni_params_lock", "omni_buffers_lock",
    "ins", "inputs",
    "outs", "outputs",
    "parameters", "params",
    "bufs", "buffers",
    "init", "initialize", "initialise", "build",
    "perform", "sample",
    "samplerate", "bufsize",
    "sig", "sig32", "sig64",
    "signal", "signal32", "signal64",
    "Data", "Buffer", "Delay"
]
