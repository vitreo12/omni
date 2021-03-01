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

import ../alloc/omni_alloc
import ../print/omni_print

const Omni_AutoMemSize = 50

type
    C_void_ptr_ptr = ptr UncheckedArray[pointer] #void**

    #use Omni_AutoMem_struct and not _omni_struct because _omni_struct is 
    #reserved for the REAL omni `struct` handling!
    Omni_AutoMem_struct* = object
        num_allocs* : int
        allocs*     : C_void_ptr_ptr 
    
    Omni_AutoMem* = ptr Omni_AutoMem_struct

proc omni_create_omni_auto_mem*() : Omni_AutoMem {.inline.} =
    let 
        auto_mem_ptr = omni_alloc0(culong(sizeof(Omni_AutoMem_struct))) 
        auto_mem = cast[Omni_AutoMem](auto_mem_ptr)
    
    if isNil(auto_mem_ptr):
        return auto_mem     #This already is cast[Omni_AutoMem](nil)

    let auto_mem_allocs_ptr = omni_alloc0(culong(sizeof(pointer) * Omni_AutoMemSize))
    
    if isNil(auto_mem_allocs_ptr):
        omni_free(auto_mem_ptr)
        return cast[Omni_AutoMem](nil)

    auto_mem.allocs = cast[C_void_ptr_ptr](auto_mem_allocs_ptr)
    auto_mem.num_allocs = 0
    return auto_mem

proc omni_auto_mem_register_child*(auto_mem : Omni_AutoMem, child : pointer) : void {.inline.} =
    if isNil(auto_mem):
        return

    if isNil(auto_mem.allocs):
        return

    when defined(omni_debug):
        omni_print_str("Omni_AutoMem: registering child:")
        omni_print_int(cint(cast[uint](child)))
    
    #Increment after assignment (so it starts at 0, and realloc will happen when last allocation in the array is reached)
    auto_mem.allocs[auto_mem.num_allocs] = child
    auto_mem.num_allocs += 1

    #Increment total size and realloc when reaching limit
    if (auto_mem.num_allocs mod Omni_AutoMemSize) == 0:
        let new_length = int(auto_mem.num_allocs + Omni_AutoMemSize)
        
        when defined(omni_debug):
            omni_print_str("Omni_AutoMem: reached allocs limit, reallocating memory with new length:")
            omni_print_int(cint(new_length))
        
        let auto_mem_allocs_ptr = omni_realloc(cast[pointer](auto_mem.allocs), culong(sizeof(pointer) * new_length))
        auto_mem.allocs = cast[C_void_ptr_ptr](auto_mem_allocs_ptr)

proc omni_auto_mem_remove_child*[T : SomeInteger](auto_mem : Omni_AutoMem, index : T) : void {.inline.} =
    if isNil(auto_mem):
        return

    if isNil(auto_mem.allocs):
        return

    let child = auto_mem.allocs[index]
    
    if isNil(child):
        return

    when defined(omni_debug):
        omni_print_debug("Omni_AutoMem: deleting child:")
        omni_print_int(cint(cast[uint](child)))
    
    omni_free(child)
    auto_mem.allocs[index] = cast[pointer](nil) #reset previus entry with nil ptr
    auto_mem.num_allocs -= 1

proc omni_auto_mem_remove_children*(auto_mem : Omni_AutoMem) : void {.inline.} =
    if isNil(auto_mem):
        return

    if isNil(auto_mem.allocs):
        return

    let num_allocs = auto_mem.num_allocs
    if num_allocs > 0:
        for i in 0..(num_allocs-1):
            auto_mem.omni_auto_mem_remove_child(i)
    
    #Reset count
    auto_mem.num_allocs = 0

proc omni_auto_mem_free*(auto_mem : Omni_AutoMem, free_children : bool = true) : void {.inline.} =
    if isNil(auto_mem):
        return

    if isNil(auto_mem.allocs):
        return

    if free_children:
        auto_mem.omni_auto_mem_remove_children()
    
    omni_free(cast[pointer](auto_mem.allocs))
    omni_free(cast[pointer](auto_mem))