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

import ../alloc/omni_alloc
import ../print/omni_print

const OmniAutoMemSize = 100

type
    C_void_ptr_ptr = ptr UncheckedArray[pointer] #void**

    OmniAutoMem* = object
        num_allocs : int
        allocs     : C_void_ptr_ptr 

proc allocInitOmniAutoMem*() : ptr OmniAutoMem {.inline.} =
    let auto_mem_ptr = omni_alloc0(culong(sizeof(OmniAutoMemSize))) 
    
    if isNil(auto_mem_ptr):
        return

    let auto_mem = cast[ptr OmniAutoMem](auto_mem_ptr)

    let auto_mem_allocs_ptr = omni_alloc0(culong(sizeof(pointer) * OmniAutoMemSize))
    
    if isNil(auto_mem_allocs_ptr):
        auto_mem.allocs = nil
        return

    auto_mem.allocs = cast[C_void_ptr_ptr](auto_mem_allocs_ptr)
    auto_mem.num_allocs = 0
    return auto_mem

proc registerChild*(auto_mem : ptr OmniAutoMem, child : pointer) : void {.inline.} =
    if isNil(auto_mem):
        return

    if isNil(auto_mem.allocs):
        return

    #Increment after assignment (so it starts at 0, and realloc will happen when last allocation in the array is reached)
    #omni_print_debug("OmniAutoMem: registering child: ", culong(cast[uint](child)))
    auto_mem.allocs[auto_mem.num_allocs] = child
    auto_mem.num_allocs += 1

    #Increment total size and realloc when reaching limit
    if (auto_mem.num_allocs mod OmniAutoMemSize) == 0:
        let new_length = int(auto_mem.num_allocs + OmniAutoMemSize)
        omni_print_debug("OmniAutoMem: reached allocs limit, reallocating memory with new length: ", culong(new_length))
        let auto_mem_allocs_ptr = omni_realloc(cast[pointer](auto_mem.allocs), culong(sizeof(pointer) * new_length))
        auto_mem.allocs = cast[C_void_ptr_ptr](auto_mem_allocs_ptr)

proc removeChild*[T : SomeInteger](auto_mem : ptr OmniAutoMem, index : T) : void {.inline.} =
    if isNil(auto_mem):
        return

    if isNil(auto_mem.allocs):
        return

    let child = auto_mem.allocs[index]
    
    if isNil(child):
        return

    #omni_print_debug("OmniAutoMem: deleting child: ", culong(cast[uint](child)))
    omni_free(child)
    auto_mem.allocs[index] = cast[pointer](nil) #reset previus entry with nil ptr
    auto_mem.num_allocs -= 1

proc removeChildren*(auto_mem : ptr OmniAutoMem) : void {.inline.} =
    if isNil(auto_mem):
        return

    if isNil(auto_mem.allocs):
        return

    let num_allocs = auto_mem.num_allocs
    if num_allocs > 0:
        for i in 0..(num_allocs-1):
            auto_mem.removeChild(i)
    
    #Reset count
    auto_mem.num_allocs = 0

proc freeOmniAutoMem*(auto_mem : ptr OmniAutoMem) : void {.inline.} =
    if isNil(auto_mem):
        return

    if isNil(auto_mem.allocs):
        return

    auto_mem.removeChildren()
    omni_free(cast[pointer](auto_mem.allocs))
    omni_free(cast[pointer](auto_mem))