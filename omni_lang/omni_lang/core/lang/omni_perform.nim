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

            for full_buffer_path in full_buffers_path:
                #expand the string like "ugen.myVariable_let.myBuffer" to a parsed dot syntax.
                let parsed_dot_syntax = parseExpr(full_buffer_path)

                #call the "get_buffer" procedure on the buffer, using the "Buffer.input_num" as index for "ins_Nim" channel
                var new_buffer = nnkCall.newTree(
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
                
                get_buffers_section.add(new_buffer)

                #when multithread buffers compilation, add the unlock_buffer() calls to the unlock_buffers() template
                when defined(multithreadBuffers):
                    var new_unlock_buffer = nnkCall.newTree(
                        newIdentNode("unlock_buffer"),
                        parsed_dot_syntax
                    )

                    multithread_unlock_buffers_body.add(new_unlock_buffer)

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
    result.add(get_buffers_section)
    
    #When multithread buffers compilation, add the unlock template 
    when defined(multithreadBuffers):
        
        #If no buffers were found, simply have a discard statement on the template.
        if multithread_unlock_buffers_body.len < 1:
            multithread_unlock_buffers_body.add(nnkDiscardStmt.newTree(newEmptyNode()))

        multithread_unlock_buffers_template_def.add(multithread_unlock_buffers_body)
        result.add(multithread_unlock_buffers_template_def)

#Unpack the fields of the ugen. Objects will be passed as unsafeAddr, to get their direct pointers. What about other inbuilt types other than floats, however??n
macro unpackUGenVariables*(t : typed) =
    return unpackUGenVariablesProc(t)

#Simply cast the inputs from SC in a indexable form in Nim
macro castInsOuts*() =
    return quote do:
        when defined(performBits32):
            let 
                ins_Nim  {.inject.}  : CFloatPtrPtr = cast[CFloatPtrPtr](ins_SC)
                outs_Nim {.inject.}  : CFloatPtrPtr = cast[CFloatPtrPtr](outs_SC)
        
        when defined(performBits64):
            let 
                ins_Nim  {.inject.}  : CDoublePtrPtr = cast[CDoublePtrPtr](ins_SC)
                outs_Nim {.inject.}  : CDoublePtrPtr = cast[CDoublePtrPtr](outs_SC)

#Need to use a template with {.dirty.} pragma to not hygienize the symbols to be like "ugen1123123", but just as written, "ugen".
template perform*(code_block : untyped) {.dirty.} =

    #used in SC
    when defined(performBits32):
        proc OmniPerform*(ugen_void : pointer, bufsize : cint, ins_SC : ptr ptr cfloat, outs_SC : ptr ptr cfloat) : void {.exportc: "OmniPerform".} =    
            #[
            #Add the templates needed for OmniPerform to unpack variable names declared with "var" in cosntructor
            generateTemplatesForPerformVarDeclarations()

            #Cast the void* to UGen*
            let ugen = cast[ptr UGen](ugen_void)

            #cast ins and outs
            castInsOuts()

            #Unpack the variables at compile time. It will also expand on any Buffer types.
            unpackUGenVariables(UGen)
            ]#

            #Append the whole code block, Wrap it in parse_block_for_variables in order to not have to declare vars/lets
            parse_block_for_variables(code_block, false, true)

            #UNLOCK buffers when multithread buffers are used...
            when defined(multithreadBuffers):
                unlock_buffers()

    #used in Max/pd
    when defined(performBits64):
        proc OmniPerform*(ugen_void : pointer, bufsize : clong, ins_SC : ptr ptr cdouble, outs_SC : ptr ptr cdouble) : void {.exportc: "OmniPerform".} =    

            #Append the whole code block, Wrap it in parse_block_for_variables in order to not have to declare vars/lets
            parse_block_for_variables(code_block, false, true)

            #UNLOCK buffers when multithread buffers are used...
            when defined(multithreadBuffers):
                unlock_buffers()

    #Write IO infos to txt file... This should be fine here in perform, as any omni file must provide a perform block to be compiled.
    when defined(writeIO):
        import os
        
        #static == compile time block
        static:
            let text = $omni_inputs & "\n" & $ugen_input_names & "\n" & $omni_outputs
            let fullPathToNewFolder = getTempDir() #this has been passed in as command argument with -d:tempDir=fullPathToNewFolder
            writeFile($fullPathToNewFolder & "IO.txt", text)

#Simply wrap the code block in a for loop. Still marked as {.dirty.} to export symbols to context.
#[ template sample*(code_block : untyped) {.dirty.} =
    #Right before sample, define the new in1, in2, etc... macro for single sample retireval
    generate_inputs_templates(omni_inputs, 1)

    #Right before sample, define the new out1, out2, etc... macro for single sample retireval
    generate_outputs_templates(omni_outputs, 1)

    for audio_index_loop in 0..(bufsize - 1):
        parse_block_for_variables(code_block, false, true)
    
    #This is in case the user accesses in1, in2, etc again after sample block. 
    #Since the template has been changed, now it would still read kr in the perform block.
    let audio_index_loop = 0 ]#