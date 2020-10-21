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

#C file to compile together
{.compile: "./omni_samplerate_bufsize.c".}

#Pass optimization flag to C compiler
{.localPassc: "-O3".}
{.passC: "-O3".}

proc omni_get_samplerate_C*() : cdouble {.importc: "omni_get_samplerate_C", cdecl.}
proc omni_get_bufsize_C*()    : cint    {.importc: "omni_get_bufsize_C", cdecl.}

proc omni_get_samplerate*() : float {.inline.} =
    return float(omni_get_samplerate_C())

proc omni_get_bufsize*() : int {.inline.} =
    return int(omni_get_bufsize_C())

#Make this just "samplerate"
template get_samplerate*() : untyped =
    omni_get_samplerate()

#Make this just "bufsize"
template get_bufsize*() : untyped =
    omni_get_bufsize()