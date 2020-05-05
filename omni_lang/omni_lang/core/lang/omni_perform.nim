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

import macros
    
proc unpackUGenVariablesProc(t : NimNode) : NimNode {.compileTime.} =
    result = nnkStmtList.newTree()

    var 
        let_section = nnkLetSection.newTree()
        get_buffers = nnkCall.newTree(newIdentNode("get_buffers"))

    let type_def = getImpl(t)
    
    #[
        Result would be: ("var" declared fields are retrieved with the template generated in constructor)
        let
            phasor     = unsafeAddr ugen.phasor_let (or phasor_var)   (object types are passed by pointer. "_let" or "_var" here doesn't make any difference. obj is still passed by pointer, but immutable (can't change the pointer to another object of same type))
            sampleRate = ugen.sampleRate_let                          (inbuilt types declared as "let" are passed as immutables)
    ]#
    for ident_def in type_def[2][2]:
        let 
            var_name = ident_def[0]
            var_desc = ident_def[1]
        
        var 
            var_name_string = var_name.strVal()
            temp_var_desc = ident_def[1]
            ident_def_stmt : NimNode

        #This bit of code will always extract the symbol type out of any composite expression,
        #Be it a generic type, a ptr, a ref type, a ptr ptr, etc...
        while temp_var_desc.kind != nnkSym:
            temp_var_desc = temp_var_desc[0]

        let var_desc_type_def = getImpl(temp_var_desc)
        
        #case for structs:
        #someData = ugen.someData_let (or someData_var)
        if var_desc.kind == nnkPtrTy or var_desc.kind == nnkRefTy:
            
            let var_name_ext = var_name_string[len(var_name_string) - 3..var_name_string.high]
            
            #If a struct is declared as var, it's an error! This should be fixed to still allow to do it.
            if var_name_ext == "var":
                error($(var_name_string[0 .. len(var_name_string) - 5]) & " is declared as \"var\". This is not allowed for structs. Use \"let\" instead.")
                
            ident_def_stmt = nnkIdentDefs.newTree(
                newIdentNode(var_name_string[0 .. len(var_name_string) - 5]),   #name of the variable, stripped off the "_var" and "_let" strings
                newEmptyNode(),
                nnkDotExpr.newTree(
                    newIdentNode("ugen"),
                    newIdentNode(var_name_string)                         #name of the variable
                )
            )

        #Variables with in-built types. They return nnkNilLit
        elif var_desc_type_def.kind == nnkNilLit:
            #var variables
            #phase_var = unsafeAddr ugen.phase_var.
            #phase_var is then accessed via the "phase" template (which is the code used by the user), which returns pointer dereferencing "phase_var[]"
            if var_name_string[len(var_name_string) - 4 .. len(var_name_string) - 1] == "_var":
                ident_def_stmt = nnkIdentDefs.newTree(
                    newIdentNode(var_name_string),                 #name of the variable
                    newEmptyNode(),
                    nnkCommand.newTree(
                        newIdentNode("unsafeAddr"),
                        nnkDotExpr.newTree(
                            newIdentNode("ugen"),
                            newIdentNode(var_name_string)          #name of the variable
                        )
                    )
                )
            
            #let variables
            #sampleRate = ugen.sampleRate_let
            #sampleRate will be then be normally accessed as an immutable inside the perform/sample statements.
            elif var_name_string[len(var_name_string) - 4 .. len(var_name_string) - 1] == "_let":
                ident_def_stmt = nnkIdentDefs.newTree(
                    newIdentNode(var_name_string[0 .. len(var_name_string) - 5]),        #name of the variable WITHOUT "_let"
                    newEmptyNode(),
                    nnkDotExpr.newTree(
                        newIdentNode("ugen"),
                        newIdentNode(var_name_string),    #name of the variable inside ugen, with "_let"
                    )
                )

        let_section.add(ident_def_stmt)
    
    result.add(let_section)
    result.add(get_buffers)

#Unpack the fields of the ugen. Objects will be passed as unsafeAddr, to get their direct pointers. What about other inbuilt types other than floats, however??n
macro unpackUGenVariables*(t : typed) =
    return unpackUGenVariablesProc(t)

#Simply cast the inputs from SC in a indexable form in Nim
macro castInsOuts32*() =
    return quote do:
        let 
            ins_Nim  {.inject.}  : CFloatPtrPtr = cast[CFloatPtrPtr](ins_ptr)
            outs_Nim {.inject.}  : CFloatPtrPtr = cast[CFloatPtrPtr](outs_ptr)

macro castInsOuts64*() =
    return quote do:
        let 
            ins_Nim  {.inject.}  : CDoublePtrPtr = cast[CDoublePtrPtr](ins_ptr)
            outs_Nim {.inject.}  : CDoublePtrPtr = cast[CDoublePtrPtr](outs_ptr)

template performInner*(code_block : untyped) {.dirty.} =
    #If ins / outs are not declared, declare them!
    when not declared(declared_inputs):
        ins 1

    when not declared(declared_outputs):
        outs 1

    #Create an empty init block if one wasn't defined by the user
    when not declared(init_block):
        init:
            discard
    
    template unlock_buffers() : untyped {.dirty.} =
        when at_least_one_buffer:
            when not declared(Buffer):
                error("No Buffer module declared! Buffers are only supported in wrappers around omni, like omnicollider and omnimax.")
            
            when defined(multithreadBuffers):
                if allocated_buffers123456789 > 0:
                    for i in (0..allocated_buffers123456789-1):
                        let buffer_to_unlock_123456789 = cast[Buffer](ugen_auto_buffer.allocs[i])
                        unlock_buffer(buffer_to_unlock_123456789)

    template get_buffers() : untyped {.dirty.} =
        when at_least_one_buffer:
            when not declared(Buffer):
                error("No Buffer module declared! Buffers are only supported in wrappers around omni, like omnicollider and omnimax.")

            let allocated_buffers123456789 = ugen_auto_buffer.num_allocs
            if allocated_buffers123456789 > 0:
                for i in (0..allocated_buffers123456789-1):
                    let buffer_to_get_123456789 = cast[Buffer](ugen_auto_buffer.allocs[i])
                    if not get_buffer(buffer_to_get_123456789, ins_Nim[buffer_to_get_123456789.input_num][0]):
                        #print("ERROR: Omni: failed to get_buffer.")
                        for audio_channel in (0..omni_outputs-1):
                            for audio_index in (0..bufsize-1):
                                outs_Nim[audio_channel][audio_index] = 0.0
                        unlock_buffers()
                        return

    when defined(performBits32):
        proc Omni_UGenPerform32(ugen_ptr : pointer, ins_ptr : ptr ptr cfloat, outs_ptr : ptr ptr cfloat, bufsize : cint) : void {.export_Omni_UGenPerform32.} =    
            #Needed to be passed to all defs
            var ugen_call_type {.inject, noinit.} : typedesc[PerformCall]
            
            #standard perform block
            when declared(perform_block):
                parse_block_for_variables(code_block, false, true, bits_32_or_64_typed = false)
            
            #sample block without perform
            else:
                parse_block_for_variables(code_block, false, true, true, false)

            #UNLOCK buffers when multithread buffers are used
            when defined(multithreadBuffers):
                unlock_buffers()

    when defined(performBits64):
        proc Omni_UGenPerform64(ugen_ptr : pointer, ins_ptr : ptr ptr cdouble, outs_ptr : ptr ptr cdouble, bufsize : cint) : void {.export_Omni_UGenPerform64.} =    
            #Needed to be passed to all defs
            var ugen_call_type {.inject, noinit.} : typedesc[PerformCall]

            #standard perform block
            when declared(perform_block):
                parse_block_for_variables(code_block, false, true, bits_32_or_64_typed = true)
            
            #sample block without perform
            else:
                parse_block_for_variables(code_block, false, true, true, true)

            #UNLOCK buffers when multithread buffers are used
            when defined(multithreadBuffers):
                unlock_buffers()

    #Write IO infos to txt file... This should be fine here in perform, as any omni file must provide a perform block to be compiled.
    when defined(writeIO):
        import os
        
        #static == compile time block
        static:
            var text = $omni_inputs & "\n" & $omni_input_names_const & "\n" 
            
            for index, default_val in omni_defaults_const:
                if index == (omni_inputs - 1):
                    text.add($default_val & "\n") 
                    break
                text.add($default_val & ",")

            text.add($omni_outputs & "\n" & omni_output_names_const)

            #this has been passed in as command argument with -d:tempDir
            let fullPathToNewFolder = getTempDir()
            writeFile($fullPathToNewFolder & "IO.txt", text)

#Need to use a template with {.dirty.} pragma to not hygienize the symbols to be like "ugen1123123", but just as written, "ugen".
template perform*(code_block : untyped) {.dirty.} =
    let perform_block {.compileTime.} = true
    performInner(code_block)

#Run perform inner, but directly to the for loop
template sample*(code_block : untyped) {.dirty.} =
    when not declared(perform_block):
        performInner(code_block)
    else:
        static:
            error("\'sample\': there already is a \'perform\' block declared.")