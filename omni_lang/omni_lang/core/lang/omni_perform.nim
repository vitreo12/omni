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

import macros, strutils
from omni_io import ins_buffers_list, params_buffers_list
    
proc unpackUGenVariablesProc(t : NimNode) : NimNode {.compileTime.} =
    result = nnkStmtList.newTree()

    var 
        let_section = nnkLetSection.newTree()
        lock_buffers = nnkCall.newTree(
            newIdentNode("lock_buffers")
        )
        unpack_params = nnkCall.newTree(
            newIdentNode("unpack_params_perform")
        )

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
            
            #If a struct is declared as var, it's an error! This should be fixed to still allow to do it.
            if var_name_string.endsWith("var"):
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
            if var_name_string.endsWith("_var"):
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
            elif var_name_string.endsWith("_let"):
                ident_def_stmt = nnkIdentDefs.newTree(
                    newIdentNode(var_name_string[0 .. len(var_name_string) - 5]),        #name of the variable WITHOUT "_let"
                    newEmptyNode(),
                    nnkDotExpr.newTree(
                        newIdentNode("ugen"),
                        newIdentNode(var_name_string),    #name of the variable inside ugen, with "_let"
                    )
                )

        if ident_def_stmt != nil:
            let_section.add(ident_def_stmt)
    
    result.add(
        let_section,
        lock_buffers,
        unpack_params
    )
    
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

#buffers_list is a compile time array. This generates two templates (lock_buffers and unlock_buffers)
#unlock_buffers is generated first because it's used in lock_buffers to unlock all buffers in case of error in locking one
macro generate_lock_unlock_buffers*() : untyped =
    result = nnkStmtList.newTree()

    var 
        unlock_buffers_body = nnkStmtList.newTree()
        unlock_buffers_template = nnkTemplateDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("unlock_buffers")
            ),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("untyped")
            ),
            nnkPragma.newTree(
                newIdentNode("dirty")
            ),
            newEmptyNode(),
            nnkStmtList.newTree(
                nnkWhenStmt.newTree(
                    nnkElifBranch.newTree(
                    nnkInfix.newTree(
                        newIdentNode("and"),
                        newIdentNode("at_least_one_buffer"),
                        nnkCall.newTree(
                            newIdentNode("defined"),
                            newIdentNode("multithreadBuffers")
                        )
                    ),
                    unlock_buffers_body
                    )
                )
            )
        )
        
        lock_buffers_body = nnkStmtList.newTree()
        lock_buffers_template = nnkTemplateDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("lock_buffers")
            ),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("untyped")
            ),
            nnkPragma.newTree(
                newIdentNode("dirty")
            ),
            newEmptyNode(),
            nnkStmtList.newTree(
                nnkWhenStmt.newTree(
                    nnkElifBranch.newTree(
                        newIdentNode("at_least_one_buffer"),
                        lock_buffers_body
                    )
                )
            )
        )

    #Generate from input
    for buffer in ins_buffers_list:
        unlock_buffers_body.add(
            nnkCall.newTree(
                newIdentNode("unlock_buffer"),
                buffer
            )
        )

        lock_buffers_body.add(
            nnkIfStmt.newTree(
                nnkElifBranch.newTree(
                    nnkPrefix.newTree(
                        newIdentNode("not"),
                        nnkCall.newTree(
                            newIdentNode("lock_buffer_input"),
                            buffer,
                            nnkBracketExpr.newTree(
                                nnkBracketExpr.newTree(
                                    newIdentNode("ins_Nim"),
                                    nnkDotExpr.newTree(
                                        buffer,
                                        newIdentNode("input_num")
                                    )
                                ),
                                newLit(0)
                            )
                        )
                    ),
                    nnkStmtList.newTree(
                        nnkForStmt.newTree(
                            newIdentNode("audio_channel"),
                            nnkPar.newTree(
                                nnkInfix.newTree(
                                    newIdentNode(".."),
                                    newLit(0),
                                    nnkInfix.newTree(
                                        newIdentNode("-"),
                                        newIdentNode("omni_outputs"),
                                        newLit(1)
                                    )
                                )
                            ),
                            nnkStmtList.newTree(
                                nnkForStmt.newTree(
                                newIdentNode("audio_index"),
                                nnkPar.newTree(
                                    nnkInfix.newTree(
                                        newIdentNode(".."),
                                        newLit(0),
                                        nnkInfix.newTree(
                                            newIdentNode("-"),
                                            newIdentNode("bufsize"),
                                            newLit(1)
                                        )
                                    )
                                ),
                                nnkStmtList.newTree(
                                    nnkAsgn.newTree(
                                        nnkBracketExpr.newTree(
                                            nnkBracketExpr.newTree(
                                                newIdentNode("outs_Nim"),
                                                newIdentNode("audio_channel")
                                            ),
                                            newIdentNode("audio_index")
                                        ),
                                        newLit(0.0)
                                    )
                                )
                                )
                            )
                        ),
                        nnkCall.newTree(
                            newIdentNode("unlock_buffers")
                        ),
                        nnkReturnStmt.newTree(
                            newEmptyNode()
                        )
                    )
                )
            )
        )

    #Generate from param
    for buffer in params_buffers_list:
        error repr buffer

    result.add(
        unlock_buffers_template,
        lock_buffers_template
    )

    #error repr result

template perform_inner*(code_block : untyped) {.dirty.} =
    #If ins / outs are not declared, declare them!
    when not declared(declared_inputs):
        ins 1

    when not declared(declared_outputs):
        outs 1

    #Create an empty init block if one wasn't defined by the user
    when not declared(init_block):
        init:
            discard

    #Create lock_buffers and unlock_buffers templates
    #unlock_buffers is generated first because it's used in lock_buffers to unlock all buffers in case of error in locking one
    generate_lock_unlock_buffers()
    
    #[
    #dynamic unlock_buffers
    template unlock_buffers*() : untyped {.dirty.} =
        when at_least_one_buffer:
            when defined(multithreadBuffers):
                if allocated_buffers123456789 > 0:
                    for i in (0..allocated_buffers123456789-1):
                        let buffer_to_unlock_123456789 = cast[Buffer](ugen_auto_buffer.allocs[i])
                        unlock_buffer(buffer_to_unlock_123456789)

    #dynamic unlock_buffers
    template lock_buffers*() : untyped {.dirty.} =
        when at_least_one_buffer:
            let allocated_buffers123456789 = ugen_auto_buffer.num_allocs
            if allocated_buffers123456789 > 0:
                for i in (0..allocated_buffers123456789-1):
                    let buffer_to_get_123456789 = cast[Buffer](ugen_auto_buffer.allocs[i])
                    if not lock_buffer(buffer_to_get_123456789, ins_Nim[buffer_to_get_123456789.input_num][0]):
                        #print("ERROR: Omni: failed to lock_buffer.")
                        for audio_channel in (0..omni_outputs-1):
                            for audio_index in (0..bufsize-1):
                                outs_Nim[audio_channel][audio_index] = 0.0
                        unlock_buffers()
                        return
    ]#

    #Code shouldn't be parsed twice for 32/64. Find a way to do it just once.
    when defined(performBits32):
        proc Omni_UGenPerform32*(ugen_ptr : pointer, ins_ptr : ptr ptr cfloat, outs_ptr : ptr ptr cfloat, bufsize : cint) : void {.exportc: "Omni_UGenPerform32", dynlib.} =    
            #Needed to be passed to all defs
            var ugen_call_type {.inject, noinit.} : typedesc[PerformCall]

            #standard perform block
            when declared(perform_block):
                parse_block_untyped(code_block, false, true, bits_32_or_64_typed = false)
            
            #sample block without perform
            else:
                parse_block_untyped(code_block, false, true, true, false, bits_32_or_64_typed = false)

            #UNLOCK buffers when multithread buffers are used
            when defined(multithreadBuffers):
                unlock_buffers()

    when defined(performBits64):
        proc Omni_UGenPerform64*(ugen_ptr : pointer, ins_ptr : ptr ptr cdouble, outs_ptr : ptr ptr cdouble, bufsize : cint) : void {.exportc: "Omni_UGenPerform64", dynlib.} =    
            #Needed to be passed to all defs
            var ugen_call_type {.inject, noinit.} : typedesc[PerformCall]

            #standard perform block
            when declared(perform_block):
                parse_block_untyped(code_block, false, true, bits_32_or_64_typed = true)
            
            #sample block without perform
            else:
                parse_block_untyped(code_block, false, true, true, false, bits_32_or_64_typed = true)

            #UNLOCK buffers when multithread buffers are used
            when defined(multithreadBuffers):
                unlock_buffers()

    #Write IO infos to txt file... This should be fine here in perform, as any omni file must provide a perform block to be compiled.
    when defined(writeIO):
        import os
        
        #static == compile time block
        static:
            var text = $omni_inputs & "\n" & $omni_input_names_const & "\n" 
            
            for index, default_val in omni_input_defaults_const:
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
    perform_inner(code_block)

#Run perform inner, but directly to the for loop
template sample*(code_block : untyped) {.dirty.} =
    when not declared(perform_block):
        perform_inner(code_block)
    else:
        static:
            error("sample: there already is a 'perform' block declared.")