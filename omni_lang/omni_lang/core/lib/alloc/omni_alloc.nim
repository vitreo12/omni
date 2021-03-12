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

#C file to compile together
{.compile: "./omni_alloc.c".}

#Pass optimization flag to C compiler
{.localPassc: "-O3".}
{.passC: "-O3".}

proc omni_alloc_C*(size : csize_t)  : pointer {.importc: "omni_alloc_C", cdecl.}
proc omni_free_C*(in_ptr : pointer) : void    {.importc: "omni_free_C", cdecl.}

proc omni_alloc*[N : SomeNumber](size : N)  : pointer {.inline, noSideEffect, raises:[].} =
    when N is csize_t:
      return omni_alloc_C(size)
    else:
      return omni_alloc_C(csize_t(size))

proc omni_alloc0*[N : SomeNumber](size : N) : pointer {.inline, noSideEffect, raises:[].} =
    when N is csize_t:
      let long_size = size
    else:
      let long_size = csize_t(size)
    
    let mem = omni_alloc_C(long_size)

    if not mem.isNil:
        zeroMem(mem, long_size)
    return mem

#Custom realloc implementation: it is only needed in Omni_AutoMem when surpassing the limit of
#objects, so it does not need to be performant. It's just more convenient when writing a parser to
#just pass a "alloc" and a "free" function.
proc omni_realloc*[N : SomeNumber](in_ptr : pointer, size : N) : pointer {.inline, noSideEffect, raises:[].} =
    if in_ptr.isNil:
        return nil
    
    when N is csize_t:
      let long_size = size
    else:
      let long_size = csize_t(size)
    
    let new_mem = omni_alloc_C(long_size)
    
    if not new_mem.isNil:
        copyMem(new_mem, in_ptr, long_size)
        omni_free_C(in_ptr)
        return new_mem

    omni_free_C(in_ptr)
    return nil

proc omni_realloc0*[N : SomeNumber](in_ptr : pointer, size : N) : pointer {.inline, noSideEffect, raises:[].} =
    if in_ptr.isNil:
        return nil

    when N is csize_t:
      let long_size = size
    else:
      let long_size = csize_t(size)
    
    let new_mem = omni_alloc0(long_size)
    
    if not new_mem.isNil:
        copyMem(new_mem, in_ptr, long_size)
        omni_free_C(in_ptr)
        return new_mem

    omni_free_C(in_ptr)
    return nil

proc omni_free*(in_ptr : pointer) : void {.inline, noSideEffect, raises:[].} =
    omni_free_C(in_ptr)

# ===================================================== #
# Discard the use of alloc / alloc0 / realloc / dealloc #
# ===================================================== #

proc alloc*[N : SomeNumber](size : N) : void =
    {.fatal: "'alloc' is not supported. Use 'Data' to allocate memory.".}

proc alloc0*[N : SomeNumber](size : N) : void =
    {.fatal: "'alloc0' is not supported. Use 'Data' to allocate memory.".}

proc realloc*[N : SomeNumber](in_ptr : pointer, size : N) : void =
    {.fatal:"'realloc' is not supported. Use 'Data' to allocate memory.".}

#This does not work as it's already a proc. The other ones are actually templates in Nim's internals
#[ proc dealloc*(in_ptr : pointer) : void =
    static:
        error("dealloc is not supported") ]#
