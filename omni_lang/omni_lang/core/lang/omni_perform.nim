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

proc findBuffersRecursive(t : NimNode, upper_var_name_string : string, full_buffers_path : var seq[string]) : void {.compileTime.} =
    let type_def = getTypeImpl(t)
    
    var actual_type_def : NimNode

    #If it's a pointer, exctract
    if type_def.kind == nnkPtrTy:
        
        #if generic
        if type_def[0].kind == nnkBracketExpr:
            actual_type_def = getTypeImpl(type_def[0][0])
        else:
            actual_type_def = getTypeImpl(type_def[0])

    #Pass the definition through
    else:
        actual_type_def = type_def
    
    #If it's not an object type, abort the search.
    if actual_type_def.kind != nnkObjectTy:
        return

    let rec_list = actual_type_def[2]

    for ident_defs in rec_list:
        let
            var_name = ident_defs[0]
            var_type = ident_defs[1]
        
        var type_to_inspect : NimNode

        #if generic
        if var_type.kind == nnkBracketExpr:
            type_to_inspect = var_type[0]
        else:
            type_to_inspect = var_type
        
        let 
            type_to_inspect_string = type_to_inspect.strVal()
            interp_var_name = $upper_var_name_string & "." & $(var_name.strVal())
        
        #Found a Buffer type!
        if type_to_inspect_string == "Buffer" or type_to_inspect_string == "Buffer_obj":
            #echo "Found Buffer: ", interp_var_name
            full_buffers_path.add(interp_var_name)
        
        #Run the function recursively
        findBuffersRecursive(type_to_inspect, interp_var_name, full_buffers_path)
    
proc unpackUGenVariablesProc(t : NimNode) : NimNode {.compileTime.} =
    result = nnkStmtList.newTree()

    var 
        let_section         = nnkLetSection.newTree()
        get_buffers_section = nnkStmtList.newTree()
        at_least_one_buffer = false
        
    #when multithreadBuffers compilation, define a unlock_buffers() template that will contain all the unlock_buffer calls
    when defined(multithreadBuffers):
        #template unlock_buffers() : untyped {.dirty.} =
        var 
            multithread_unlock_buffers_template_def = nnkTemplateDef.newTree(
                newIdentNode("unlock_buffers"),
                newEmptyNode(),
                newEmptyNode(),
                nnkFormalParams.newTree(
                newIdentNode("untyped")
                ),
                nnkPragma.newTree(
                newIdentNode("dirty")
                ),
                newEmptyNode()
            )

            multithread_unlock_buffers_body = nnkStmtList.newTree()

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

            ##########################
            # Look for Buffer types. #
            ##########################

            let 
                ptr_type           = var_desc[0]
                var_name_string_with_ugen = "ugen." & $var_name_string

            #seq[NimNode] to append the results to
            var full_buffers_path : seq[string]

            #If generic
            if ptr_type.kind == nnkBracketExpr:
                findBuffersRecursive(ptr_type[0], var_name_string_with_ugen, full_buffers_path)

            #Not generic
            elif ptr_type.kind == nnkSym:
                if ptr_type.strVal() == "Buffer_obj":
                    full_buffers_path.add(var_name_string_with_ugen)
                else:
                    findBuffersRecursive(ptr_type, var_name_string_with_ugen, full_buffers_path)

            #[ for full_buffer_path in full_buffers_path:
                #expand the string like "ugen.myVariable_let.myBuffer" to a parsed dot syntax.
                let parsed_dot_syntax = parseExpr(full_buffer_path)

                #Add the "failed_get_buffer" variable
                if not at_least_one_buffer:
                    get_buffers_section.add(nnkVarSection.newTree(
                        nnkIdentDefs.newTree(
                            newIdentNode("failed_get_buffer"),
                            newEmptyNode(),
                            newIdentNode("false")
                            )
                        )
                    )
                    
                    at_least_one_buffer = true

                #call the "get_buffer" procedure on the buffer, using the "Buffer.input_num" as index for "ins_Nim" channel
                #if not(get_buffer(....)):
                #   failed_get_buffer = true
                var new_buffer = nnkIfStmt.newTree(
                    nnkElifBranch.newTree(
                        nnkPar.newTree(
                            nnkPrefix.newTree(
                                newIdentNode("not"),
                                nnkPar.newTree(
                                    nnkCall.newTree(
                                        newIdentNode("get_buffer"),
                                        parsed_dot_syntax,
                                        nnkBracketExpr.newTree(
                                            nnkBracketExpr.newTree(
                                                newIdentNode("ins_Nim"),
                                                nnkDotExpr.newTree(
                                                    parsed_dot_syntax,
                                                    newIdentNode("input_num")
                                                )
                                            ),
                                            newLit(0)
                                        )
                                    )
                                )
                            )
                        ),
                        nnkStmtList.newTree(
                            nnkAsgn.newTree(
                                newIdentNode("failed_get_buffer"),
                                newIdentNode("true")
                            )
                        )
                    )
                )
    
                get_buffers_section.add(new_buffer)

                #when multithread buffers compilation, add the unlock_buffer() calls to the unlock_buffers() template
                when defined(multithreadBuffers):
                    var new_unlock_buffer = nnkCall.newTree(
                        newIdentNode("unlock_buffer"),
                        parsed_dot_syntax
                    )

                    multithread_unlock_buffers_body.add(new_unlock_buffer)
 ]#
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
    

    #Output silence and return from perform function if any of the buffers failed to acquire lock:
    #[
        if failed_get_buffer:
            for i in 0 .. omni_outs:
                for y in 0 .. bufsize - 1:
                    outs_Nim[i][y] = 0.0'f64
            unlock_buffers()
            return
    ]#
    if at_least_one_buffer:
        var append_unlock_buffers = nnkStmtList.newTree()

        when defined(multithreadBuffers):
            append_unlock_buffers.add(
                nnkCall.newTree(
                    newIdentNode("unlock_buffers")
                )
            )
        
        append_unlock_buffers.add(
            nnkReturnStmt.newTree(
                newEmptyNode()
            )
        )

        get_buffers_section.add(
            nnkIfStmt.newTree(
                nnkElifBranch.newTree(
                    newIdentNode("failed_get_buffer"),
                    nnkStmtList.newTree(
                        nnkForStmt.newTree(
                            newIdentNode("audio_out_channel"),
                            nnkInfix.newTree(
                                newIdentNode(".."),
                                newLit(0),
                                nnkPar.newTree(
                                    nnkInfix.newTree(
                                        newIdentNode("-"),
                                        newIdentNode("omni_outputs"),
                                        newLit(1)
                                    )
                                )
                            ),
                            nnkStmtList.newTree(
                                nnkForStmt.newTree(
                                    newIdentNode("audio_out_sample"),
                                    nnkInfix.newTree(
                                        newIdentNode(".."),
                                        newLit(0),
                                        nnkPar.newTree(
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
                                                    newIdentNode("audio_out_channel")
                                                ),
                                                newIdentNode("audio_out_sample")
                                            ),
                                        newLit(0.0)
                                        )
                                    )
                                )
                            )
                        ),
                        append_unlock_buffers,
                    )
                )
            )
        )

   #echo repr get_buffers_section

    result.add(let_section)

    #When multithread buffers compilation, add the unlock template 
    when defined(multithreadBuffers):
        
        #If no buffers were found, simply have a discard statement on the template.
        if multithread_unlock_buffers_body.len < 1:
            multithread_unlock_buffers_body.add(nnkDiscardStmt.newTree(newEmptyNode()))

        multithread_unlock_buffers_template_def.add(multithread_unlock_buffers_body)
        result.add(multithread_unlock_buffers_template_def)

    result.add(get_buffers_section)

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
    #Create an empty init block if one wasn't defined by the user
    when not declared(init_block):
        init:
            discard

    #used in SC
    when defined(performBits32):
        proc Omni_UGenPerform32*(ugen_ptr : pointer, ins_ptr : ptr ptr cfloat, outs_ptr : ptr ptr cfloat, bufsize : cint) : void {.exportc: "Omni_UGenPerform32", dynlib.} =    
            #standard perform block
            when declared(perform_block):
                parse_block_for_variables(code_block, false, true, bits_32_or_64_typed = false)
            
            #sample block without perform
            else:
                parse_block_for_variables(code_block, false, true, true, false)

            #UNLOCK buffers when multithread buffers are used
            when defined(multithreadBuffers):
                unlock_buffers()

    #used in Max/pd
    when defined(performBits64):
        proc Omni_UGenPerform64*(ugen_ptr : pointer, ins_ptr : ptr ptr cdouble, outs_ptr : ptr ptr cdouble, bufsize : cint) : void {.exportc: "Omni_UGenPerform64", dynlib.} =    
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
            error("sample: there already is a \"perform\" block declared.")