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
# SOFTWARE.codi

import ../../lang/omni_call_types
import ../alloc/omni_alloc
import ../auto_mem/omni_auto_mem
import ../print/omni_print
import ../math/omni_math
from   ../stdlib/omni_stdlib import cubic_interp

type ArrayPtr[T] = ptr UncheckedArray[T]

type
    Data_omni_struct*[T] = object
        data    : ArrayPtr[T]
        length  : int
        chans   : int
        size    : int

    Data*[T] = ptr Data_omni_struct[T]

    Data_omni_struct_ptr*[T] = Data[T]
     
#Having the strings as const as --gc:none is used
const
    length_error  = "WARNING: Omni: Data's length must be a positive number. Setting it to 1."
    chans_error   = "WARNING: Omni: Data's chans must be a positive number. Setting it to 1."

#Constructor interface: Data
proc Data_omni_struct_new*[S : SomeNumber, C : SomeNumber](length : S = int(1), chans : C = int(1), G1 : typedesc = typedesc[float], samplerate : float, bufsize : int, omni_struct_type : typedesc[Data_omni_struct_ptr], omni_auto_mem : Omni_AutoMem, omni_call_type : typedesc[Omni_CallType] = Omni_InitCall) : Data[G1]  {.inline.} =
    #Trying to allocate in perform block! nonono
    when omni_call_type is Omni_PerformCall:
        {.fatal: "struct 'Data': attempting to allocate memory in the 'perform' or 'sample' blocks.".}
    
    var 
        real_length = int(length)
        real_chans  = int(chans)
    
    if real_length < 1:
        print(length_error)
        real_length = 1

    if real_chans < 1:
        print(chans_error)
        real_chans = 1

    let size_data_obj = sizeof(Data_omni_struct[G1])

    #Actual object, assigned to result
    result = cast[Data[G1]](omni_alloc0(size_data_obj, omni_auto_mem))
    
    #Data of the object (the array)
    let 
        size              = real_length * real_chans
        size_data_type    = sizeof(G1)
        total_size        = csize_t(size_data_type * size)
        data              = cast[ArrayPtr[G1]](omni_alloc0(total_size, omni_auto_mem))

    #Register both the Data object and its data to the automatic memory management
    omni_auto_mem.omni_auto_mem_register_child(result)
    omni_auto_mem.omni_auto_mem_register_child(data)
    
    #Fill the object layout
    result.data = data
    result.chans  = real_chans
    result.length = real_length
    result.size   = size

#Import stuff for type manipulation
import macros, ../../lang/omni_parser, ../../lang/omni_macros_utilities

#Initialize object of type T at entry
macro omni_data_generic_default(t : typed, validity_or_getter : bool = false) : untyped =
    let validity_or_getter_bool = validity_or_getter.boolVal
    
    var type_instance = t.getTypeInst[1]

    #Convert everything to idents, or omni_find_struct_constructor_call won't work
    type_instance = typed_to_untyped(type_instance)[0]
    
    let omni_type_instance_call = omni_find_struct_constructor_call(
        nnkCall.newTree(
            type_instance
        )
    )
    
    #omni_check_datas_validity
    if not validity_or_getter_bool:
        # let print_warning = nnkCall.newTree(
        #     newIdentNode("omni_print_str"),
        #     newLit("WARNING: Omni: 'Data[" & $repr(type_instance) & "]': Not all entries have been explicitly initialized. Setting uninitialized entries to '" & $repr(type_instance) & "()'"),
        # )

        return quote do:
            data[i, y] = `omni_type_instance_call`
            # if not print_once:
                # `print_warning`
                # print_once = true

    #getter
    else:
        let print_warning = nnkStmtList.newTree(
            nnkCall.newTree(
                newIdentNode("omni_print_compose_int"),
                newLit("WARNING: Omni: 'Data[" & $repr(type_instance) & "]': Uninitialized entry at index "),
                nnkCall.newTree(
                    newIdentNode("cint"),
                    newIdentNode("actual_index")
                ),
                newLit(". Initializing it to '" & $repr(type_instance) & "()'")
            )
        )

        return quote do:
            data.data[actual_index] = `omni_type_instance_call`
            `print_warning`

#Core of omni_check_datas_validity
proc omni_check_datas_validity*[T](data : Data[T], samplerate : float, bufsize : int, omni_auto_mem : Omni_AutoMem, omni_call_type : typedesc[Omni_CallType] = Omni_InitCall) : void {.inline.} =
    when T isnot SomeNumber:
        var print_once = false
        for i in 0 ..< data.chans:
            for y in 0 ..< data.length:
                #Use Omni_PerformCall not to initialize the entry (as it would with Omni_InitCall)
                #I'm doing this in order to print the correct message just once, instead of at each read
                let entry = data.getter(i, y, 0.0, 0, cast[Omni_AutoMem](nil), Omni_PerformCall)
                if entry.isNil:
                    omni_data_generic_default(T)

############
# ITERATOR #
############

iterator items*[T](data : Data[T]) : T {.inline.} =
    for chan in 0 ..< data.chans:
        var i = 0
        while i < data.length:
            #Use Omni_PerformCall not to initialize the entry
            yield data.getter(chan, i, 0.0, 0, cast[Omni_AutoMem](nil), Omni_PerformCall)
            inc(i)

iterator pairs*[T](data: Data[T]) : tuple[key: int, val : T] {.inline.} =
    for chan in 0 ..< data.chans:
        var i = 0
        while i < data.length:
            #Use Omni_PerformCall not to initialize the entry
            yield (i, data.getter(chan, i, 0.0, 0, cast[Omni_AutoMem](nil), Omni_PerformCall))
            inc(i)

##########
# GETTER #
##########

#Print warning on out of bounds access
macro omni_data_out_of_bounds_getter(t : typed, first_or_last : bool = false) : untyped =
    var type_instance = t.getTypeInst[1]
    
    var first_or_last_str = "first"
    if first_or_last.boolVal: first_or_last_str = "last"

    let print_warning = nnkStmtList.newTree(
        nnkCall.newTree(
            newIdentNode("omni_print_compose_int"),
            newLit("WARNING: Omni: 'Data[" & $repr(type_instance) & "]': Trying to access out of bounds element at index "),
            nnkCall.newTree(
                newIdentNode("cint"),
                newIdentNode("actual_index")
            ),
            newLit(". Returning " & first_or_last_str & " element instead.")
        )
    )

    return print_warning

#Get element at chan, index
proc getter*[T](data : Data[T], channel : int = 0, index : int = 0, samplerate : float, bufsize : int, omni_auto_mem : Omni_AutoMem, omni_call_type : typedesc[Omni_CallType] = Omni_InitCall) : T {.inline, noSideEffect, raises:[].} =
    let chans = data.chans
    
    var actual_index : int
    
    if chans == 1:
        actual_index = index
    else:
        actual_index = (index * chans) + channel
    
    if actual_index >= 0 and actual_index < data.size:
        #Dynamic allocation on access in init block IF entry is nil!
        #This means that, if trying to access a nil entry, it will be initialized with the default
        #constructor of type T, same as it's done for omni_check_datas_validity.
        when omni_call_type is Omni_InitCall:
            let value = data.data[actual_index]
            when T isnot SomeNumber:
                if value.isNil:
                    omni_data_generic_default(T, true)
                    return data.data[actual_index] #This is the newly allocated object!
            
        #in perform, everything is SURELY initialized. No need to check
        return data.data[actual_index]
    
    #return first / last entry not to crash! this hints the coder to a bug in his code
    if actual_index < 0:
        omni_data_out_of_bounds_getter(T)
        return data[0, 0] #use data[,] access so it goes to .getter again, in case it needs init
    else:
        omni_data_out_of_bounds_getter(T, true)
        return data[chans - 1, data.len - 1]

#1 channel 
template `[]`*[I : SomeNumber, T](a : Data[T], i : I) : untyped =
    a.getter(0, int(i), samplerate, bufsize, omni_auto_mem, omni_call_type)

#multi channel
template `[]`*[I1 : SomeNumber, I2 : SomeNumber; T](a : Data[T], i1 : I1, i2 : I2) : untyped =
    a.getter(int(i1), int(i2), samplerate, bufsize, omni_auto_mem, omni_call_type)

#read with cubic interp
proc read_inner*[I1 : SomeNumber, I2 : SomeNumber; T : SomeNumber](data : Data[T], chan : I1, index : I2, samplerate : float, bufsize : int, omni_auto_mem : Omni_AutoMem, omni_call_type : typedesc[Omni_CallType] = Omni_InitCall) : float {.inline, noSideEffect, raises:[].} =
    let
        data_len = data.length
        chan_int = int(chan)
        index_int = int(index)
        index1 = index_int mod data_len
        index2 = (index_int + 1) mod data_len
        index3 = (index_int + 2) mod data_len
        index4 = (index_int + 3) mod data_len
        frac : float = float(index) - float(index_int)
    
    return float(cubic_interp(frac, data[chan_int, index1], data[chan_int, index2], data[chan_int, index3], data[chan_int, index4])) 

#1 channel
template read*[I : SomeNumber; T : SomeNumber](data : Data[T], index : I) : untyped =
    data.read_inner(index, samplerate, bufsize, omni_auto_mem, omni_call_type)

#multi channel
template read*[I1 : SomeNumber, I2 : SomeNumber; T : SomeNumber](data : Data[T], chan : I1, index : I2) : untyped =
    data.read_inner(chan, index, samplerate, bufsize, omni_auto_mem, omni_call_type)

##########
# SETTER #
##########

#Print warning when trying to redefine
macro omni_data_redefinition_setter(t : typed) : untyped =
    var type_instance = t.getTypeInst[1]

    let print_warning = nnkCall.newTree(
        newIdentNode("omni_print"),
        newLit("WARNING: Omni: 'Data[" & $repr(type_instance) & "]': Trying to re-instantiate an already allocated element at %d. This is not allowed.\n"),
        newIdentNode("actual_index")
    )

    return print_warning

proc setter*[T, Y](data : Data[T], channel : int = 0, index : int = 0,  x : Y, omni_call_type : typedesc[Omni_CallType] = Omni_InitCall ) : void {.inline, noSideEffect, raises:[].} =
    let chans = data.chans
    
    var actual_index : int
    
    if chans == 1:
        actual_index = index
    else:
        actual_index = (index * chans) + channel
    
    if actual_index >= 0 and actual_index < data.size:
        when T is SomeNumber and Y is SomeNumber:
            data.data[actual_index] = T(x)
        elif T is Y:
            when omni_call_type is Omni_InitCall:
                let value = data.data[actual_index]
                if not value.isNil:
                    omni_data_redefinition_setter(T)
                    return
            data.data[actual_index] = x
        else:
            {.fatal: "Data: '" & $T & "' is an invalid type for the setter function.".}

#1 channel     
template `[]=`*[I : SomeNumber, T, S](a : Data[T], i : I, x : S) : untyped =
    a.setter(int(0), int(i), x, omni_call_type)

#multi channel
template `[]=`*[I1 : SomeNumber, I2 : SomeNumber; T, S](a : Data[T], i1 : I1, i2 : I2, x : S) : untyped =
    a.setter(int(i1), int(i2), x, omni_call_type)

#########
# INFOS #
#########

proc length*[T](data : Data[T]) : int {.inline, noSideEffect, raises:[].} =
    return data.length

template len*[T](data : Data[T]) : untyped =
    data.length

proc chans*[T](data : Data[T]) : int {.inline, noSideEffect, raises:[].} =
    return data.chans

template channels*[T](data : Data[T]) : untyped =
    data.chans

proc size*[T](data : Data[T]) : int {.inline, noSideEffect, raises:[].} =
    return data.size
