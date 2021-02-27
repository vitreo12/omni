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

import macros, strutils
    
proc omni_unpack_ugen_fields_inner(t : NimNode) : NimNode {.compileTime.} =
    result = nnkStmtList.newTree()

    var 
        let_section = nnkLetSection.newTree()
        unpack_params = nnkCall.newTree(
            newIdentNode("omni_unpack_params_perform")
        )
        unpack_buffers = nnkCall.newTree(
            newIdentNode("omni_unpack_buffers_perform")
        )
        omni_lock_buffers = nnkCall.newTree(
            newIdentNode("omni_lock_buffers")
        )

    #t is the Omni_UGen
    let type_def = getImpl(t)
    
    #[
        Result would be: ("var" declared fields are retrieved with the template generated in constructor)
        let
            phasor     = unsafeAddr omni_ugen.phasor_let (or phasor_var)   (object types are passed by pointer. "_let" or "_var" here doesn't make any difference. obj is still passed by pointer, but immutable (can't change the pointer to another object of same type))
            sampleRate = omni_ugen.sampleRate_let                          (inbuilt types declared as "let" are passed as immutables)
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
        #someData = omni_ugen.someData_let (or someData_var)
        if var_desc.kind == nnkPtrTy or var_desc.kind == nnkRefTy:
            
            #If a struct is declared as var, it's an error! This should be fixed to still allow to do it.
            if var_name_string.endsWith("var"):
                error($(var_name_string[0 .. len(var_name_string) - 5]) & " is declared as 'var'. This is not allowed for structs. Use 'let' instead.")
                
            ident_def_stmt = nnkIdentDefs.newTree(
                newIdentNode(var_name_string[0 .. len(var_name_string) - 5]),   #name of the variable, stripped off the "_var" and "_let" strings
                newEmptyNode(),
                nnkDotExpr.newTree(
                    newIdentNode("omni_ugen"),
                    newIdentNode(var_name_string)                         #name of the variable
                )
            )

        #Variables with in-built types. They return nnkNilLit
        elif var_desc_type_def.kind == nnkNilLit:
            #var variables
            #phase_var = unsafeAddr omni_ugen.phase_var.
            #phase_var is then accessed via the "phase" template (which is the code used by the user), which returns pointer dereferencing "phase_var[]"
            if var_name_string.endsWith("_var"):
                ident_def_stmt = nnkIdentDefs.newTree(
                    newIdentNode(var_name_string),                 #name of the variable
                    newEmptyNode(),
                    nnkCommand.newTree(
                        newIdentNode("unsafeAddr"),
                        nnkDotExpr.newTree(
                            newIdentNode("omni_ugen"),
                            newIdentNode(var_name_string)          #name of the variable
                        )
                    )
                )
            
            #let variables
            #sampleRate = omni_ugen.sampleRate_let
            #sampleRate will be then be normally accessed as an immutable inside the perform/sample statements.
            elif var_name_string.endsWith("_let"):
                ident_def_stmt = nnkIdentDefs.newTree(
                    newIdentNode(var_name_string[0 .. len(var_name_string) - 5]), #name of the variable WITHOUT "_let"
                    newEmptyNode(),
                    nnkDotExpr.newTree(
                        newIdentNode("omni_ugen"),
                        newIdentNode(var_name_string),    #name of the variable inside omni_ugen, with "_let"
                    )
                )

        if ident_def_stmt != nil:
            let_section.add(ident_def_stmt)
    
    result.add(
        let_section,
        unpack_buffers,
        omni_lock_buffers,
        unpack_params
    )

#Unpack the fields of the omni_ugen. t is Omni_UGen here.
macro omni_unpack_ugen_fields*(t : typed) =
    return omni_unpack_ugen_fields_inner(t)

#Simply cast the inputs from C to an indexable form in Nim
template omni_cast_ins_outs32*() : untyped {.dirty.} =
    let 
        omni_ins_ptr  {.inject.}  : Float32_ptr_ptr = cast[Float32_ptr_ptr](ins_ptr)
        omni_outs_ptr {.inject.}  : Float32_ptr_ptr = cast[Float32_ptr_ptr](outs_ptr)

template omni_cast_ins_outs64*() : untyped {.dirty.} =
    let 
        omni_ins_ptr  {.inject.}  : Float64_ptr_ptr = cast[Float64_ptr_ptr](ins_ptr)
        omni_outs_ptr {.inject.}  : Float64_ptr_ptr = cast[Float64_ptr_ptr](outs_ptr)

template omni_perform_inner*(code_block : untyped) {.dirty.} =
    when not declared(omni_declared_params):
        parameters 0 #Use 'parameters' not to be confused with macro's params

    when not declared(omni_declared_buffers):
        buffers 0

    #If init wasn't declared, declare an empty one
    when not declared(omni_declared_init):
        init:
            discard
    
    #In the case of perform / sample blocks, omni_parse_block_untyped returns:
    #
    #when not declared(omni_declared_inputs):
    #   ins ..
    #
    #when not declared(omni_declared_outputs):
    #   outs ..
    #
    #template omni_perform_block_untyped() : untyped {.dirty.} =
    #   ... (untyped parsed code) ...
    #
    when declared(omni_declared_perform):
        omni_parse_block_untyped(code_block, false, true)
    #sample block without perform
    else:
        omni_parse_block_untyped(code_block, false, true, true)

    #Execute the init block AFTER the untyped parsing of the perform. 
    #This allows to use the omni_inputs / omni_outputs in init
    omni_define_init_block()

    #This can be defined in wrappers
    when declared(omni_params_pre_perform_hook):
        omni_params_pre_perform_hook()

    #This can be defined in wrappers
    when declared(omni_buffers_pre_perform_hook):
        omni_buffers_pre_perform_hook()

    #Code shouldn't be parsed twice for 32/64. Find a way to do it just once.
    when defined(omni_perform32):
        proc Omni_UGenPerform32*(omni_ugen_ptr : pointer, ins_ptr : ptr ptr cfloat, outs_ptr : ptr ptr cfloat, bufsize : cint) : void {.exportc: "Omni_UGenPerform32", dynlib, raises:[].} =    
            #Needed to be passed to all defs
            var omni_call_type {.inject, noinit.} : typedesc[Omni_PerformCall]

            #Unpack everything
            let omni_ugen = cast[Omni_UGen](omni_ugen_ptr)
            omni_cast_ins_outs32()
            omni_unpack_ins_perform(omni_inputs_names_const) #kr unpacking
            omni_unpack_ugen_fields(Omni_UGen_struct)
            omni_generate_templates_for_perform_var_declarations()

            #Run typed perform manually. untyped block is stored in the omni_perform_untyped_block() template
            omni_parse_block_typed(
                omni_perform_untyped_block(), 
                is_perform_block_typed=true
            )

            #unlock buffers only when multithread buffers are used
            when not defined(omni_buffers_disable_multithreading):
                omni_unlock_buffers()

    when defined(omni_perform64):
        proc Omni_UGenPerform64*(omni_ugen_ptr : pointer, ins_ptr : ptr ptr cdouble, outs_ptr : ptr ptr cdouble, bufsize : cint) : void {.exportc: "Omni_UGenPerform64", dynlib, raises:[].} =    
            #Needed to be passed to all defs
            var omni_call_type {.inject, noinit.} : typedesc[Omni_PerformCall]

            #Unpack everything
            let omni_ugen = cast[Omni_UGen](omni_ugen_ptr)
            omni_cast_ins_outs64()
            omni_unpack_ins_perform(omni_inputs_names_const) #kr unpacking
            omni_unpack_ugen_fields(Omni_UGen_struct)
            omni_generate_templates_for_perform_var_declarations()

            #Run typed perform manually. untyped block is stored in the omni_perform_untyped_block() template
            omni_parse_block_typed(
                omni_perform_untyped_block(), 
                is_perform_block_typed=true
            )

            #unlock buffers only when multithread buffers are used
            when not defined(omni_buffers_disable_multithreading):
                omni_unlock_buffers()

    #Write IO infos to txt file.
    #It should be fine here in perform, as any omni file must provide a perform/sample block to be compiled.
    omni_export_io()

#Need to use a template with {.dirty.} pragma to not hygienize the symbols to be like "ugen1123123", but just as written, "omni_ugen".
template perform*(code_block : untyped) {.dirty.} =
    when not declared(omni_declared_perform) and not declared(omni_declared_sample):
        let omni_declared_perform {.compileTime.} = true
        omni_perform_inner(code_block)
    else:
        {.fatal: "perform: there already is a 'perform' or 'sample' block declared.".}

#Run perform inner, but directly to the for loop
template sample*(code_block : untyped) {.dirty.} =
    when not declared(omni_declared_perform) and not declared(omni_declared_sample):
        let omni_declared_sample {.compileTime.} = true
        omni_perform_inner(code_block)
    else:
        {.fatal: "sample: there already is a 'perform' or 'sample' block declared.".}