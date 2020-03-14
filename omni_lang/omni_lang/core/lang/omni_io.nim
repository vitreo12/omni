import macros

const max_inputs_outputs = 32

const acceptedCharsForParamName = {'a'..'z', 'A'..'Z', '0'..'9', '_'}

#Generate in1, in2, in3...etc templates
macro generate_inputs_templates*(num_of_inputs : typed, generate_ar : typed) : untyped =
    var final_statement = nnkStmtList.newTree()

    #This generates:
    #[  
        THIS IS CALLED AT TOP OF SCRIPT.
        if generate_ar == 0:
            template in1*() : untyped =
                ins_Nim[0][0] 

        THIS IS CALLED RIGHT BEFORE PERFORM LOOP. IT OVERWRITES PREVIOUS ONE.
        if generate_ar == 1: 
            template in1*() : untyped =
                ins_Nim[0][audio_index_loop] 
    ]#

    var 
        num_of_inputs_VAL = num_of_inputs.intVal()
        generate_ar = generate_ar.intVal() #boolVal() doesn't work here.

    if generate_ar == 1:
        for i in 1..num_of_inputs_VAL:
            #template for AR input, named in1, in2, etc...
            let temp_in_stmt_list = nnkTemplateDef.newTree(
                newIdentNode("in" & $i),
                #nnkPostfix.newTree(
                #newIdentNode("*"),
                #newIdentNode("in" & $i),             #name of template
                #),
                newEmptyNode(),
                newEmptyNode(),
                nnkFormalParams.newTree(
                newIdentNode("untyped")
                ),
                newEmptyNode(),
                newEmptyNode(),
                nnkStmtList.newTree(
                nnkBracketExpr.newTree(
                    nnkBracketExpr.newTree(
                    newIdentNode("ins_Nim"),             #name of the ins buffer
                    newLit(int(i - 1))               #literal value
                    ),
                    newIdentNode("audio_index_loop") #name of the looping variable
                )
                )
            )

            #Accumulate result
            final_statement.add(temp_in_stmt_list)

    else:
        for i in 1..num_of_inputs_VAL:
            let temp_in_stmt_list = nnkStmtList.newTree(
                #template for KR input, named in1, in2, etc..
                nnkTemplateDef.newTree(
                    newIdentNode("in" & $i),
                    #nnkPostfix.newTree(
                    #newIdentNode("*"),
                    #newIdentNode("in" & $i),      #name of template 
                    #),
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                    newIdentNode("untyped")
                    ),
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkStmtList.newTree(
                    nnkBracketExpr.newTree(
                        nnkBracketExpr.newTree(
                        newIdentNode("ins_Nim"),             #name of the ins buffer
                        newLit(int(i - 1))               #literal value
                        ),
                        newLit(0)                        # ins[...][0]
                    )
                    )
                )
            )

            #Accumulate result
            final_statement.add(temp_in_stmt_list)

    return final_statement

#Generate in1, in2, in3...etc templates
macro generate_outputs_templates*(num_of_outputs : typed, generate_ar : typed) : untyped =
    var final_statement = nnkStmtList.newTree()

    #This generates:
    #[  
        THIS IS CALLED AT TOP OF SCRIPT.
        if generate_ar == 0:
            template out1*() : untyped =
                outs_Nim[0][0] 

        THIS IS CALLED RIGHT BEFORE PERFORM LOOP. IT OVERWRITES PREVIOUS ONE.
        if generate_ar == 1: 
            template out1*() : untyped =
                outs_Nim[0][audio_index_loop] 
    ]#

    var 
        num_of_outputs_VAL = num_of_outputs.intVal()
        generate_ar = generate_ar.intVal() #boolVal() doesn't work here.

    if generate_ar == 1:
        for i in 1..num_of_outputs_VAL:
            #template for AR output, named out1, out2, etc...
            let temp_in_stmt_list = nnkTemplateDef.newTree(
                newIdentNode("out" & $i),
                #nnkPostfix.newTree(
                #newIdentNode("*"),
                #newIdentNode("out" & $i),             #name of template
                #),
                newEmptyNode(),
                newEmptyNode(),
                nnkFormalParams.newTree(
                newIdentNode("untyped")
                ),
                newEmptyNode(),
                newEmptyNode(),
                nnkStmtList.newTree(
                nnkBracketExpr.newTree(
                    nnkBracketExpr.newTree(
                    newIdentNode("outs_Nim"),             #name of the outs buffer
                    newLit(int(i - 1))               #literal value
                    ),
                    newIdentNode("audio_index_loop") #name of the looping variable
                )
                )
            )

            #Accumulate result
            final_statement.add(temp_in_stmt_list)

    else:
        for i in 1..num_of_outputs_VAL:
            let temp_in_stmt_list = nnkStmtList.newTree(
                #template for KR output, named out1, out2, etc..
                nnkTemplateDef.newTree(
                    newIdentNode("out" & $i),
                    #nnkPostfix.newTree(
                    #newIdentNode("*"),
                    #newIdentNode("out" & $i),      #name of template 
                    #),
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                    newIdentNode("untyped")
                    ),
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkStmtList.newTree(
                    nnkBracketExpr.newTree(
                        nnkBracketExpr.newTree(
                        newIdentNode("outs_Nim"),             #name of the outs buffer
                        newLit(int(i - 1))               #literal value
                        ),
                        newLit(0)                        # outs[...][0]
                    )
                    )
                )
            )

            #Accumulate result
            final_statement.add(temp_in_stmt_list)

    return final_statement


#macro ins_2(num_of_inputs : untyped, param_names : varargs[untyped]) : untyped = 
#    return ins(num_of_inputs, param_names)

#The block form (derived from using num_of_inputs as int literal, and param_names as a code block.):
#inputs 1:
#   "freq"
macro ins*(num_of_inputs : untyped, param_names : untyped) : untyped =
    
    var 
        num_of_inputs_VAL : int
        param_names_string : string = ""
        param_names_node : NimNode

    let param_names_kind = param_names.kind

    #Must be an int literal
    if num_of_inputs.kind != nnkIntLit: #Just as the expectKind proc
        error("Expected the number of inputs to be expressed by an integer literal value")

    if param_names_kind != nnkStmtList and param_names_kind != nnkStrLit:
        error("Expected a block statement after the number of inputs")
    
    num_of_inputs_VAL = int(num_of_inputs.intVal)     #Actual value of the int literal

    if num_of_inputs_VAL < 0:
        error("Expected a positive number for inputs number")
    
    if num_of_inputs_VAL > max_inputs_outputs:
        error("Exceeded maximum number of inputs, " & $max_inputs_outputs)

    var statement_counter = 0

    #This is for the inputs 1, "freq" case... input 2, "freq", "stmt" is covered in the other macro
    if param_names_kind == nnkStrLit:
        let param_name = param_names.strVal()
        
        for individualChar in param_name:
            if not (individualChar in acceptedCharsForParamName):
                error("Invalid character " & $individualChar & $ " in input name " & $param_name)
        
        param_names_string.add($param_name & ",")
        statement_counter = 1

    #Normal block case
    else:
        for statement in param_names.children():
            if statement.kind != nnkStrLit:
                error("Expected parameter name number " & $(statement_counter + 1) & " to be a string literal value")
            
            let param_name = statement.strVal()

            for individualChar in param_name:
                if not (individualChar in acceptedCharsForParamName):
                    error("Invalid character " & $individualChar & $ " in input name " & $param_name)
            
            param_names_string.add($param_name & ",")
            statement_counter += 1

    #Remove trailing coma
    if param_names_string.len > 1:
        param_names_string = param_names_string[0..param_names_string.high-1]
    
    #Assign to node
    param_names_node = newLit(param_names_string)
    
    if statement_counter != num_of_inputs_VAL:
        error("Expected " & $num_of_inputs_VAL & " param names, got " & $statement_counter)

    return quote do: 
        const 
            omni_inputs {.inject.} = `num_of_inputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to insert variable from macro's scope
            ugen_input_names {.inject.} = `param_names_node`  #It's possible to insert NimNodes directly in the code block 
        
        generate_inputs_templates(`num_of_inputs_VAL`, 0)
        
        #Export to C
        proc get_omni_inputs() : int32 {.exportc: "get_omni_inputs".} =
            return int32(omni_inputs)

        proc get_ugen_input_names() : ptr cchar {.exportc: "get_ugen_input_names".} =
            return cast[ptr cchar](ugen_input_names)

macro ins*(num_of_inputs : untyped, param_names : varargs[untyped]) : untyped = 
    
    var 
        num_of_inputs_VAL : int
        param_names_string : string = ""
        param_names_node : NimNode

    #The other block form (derived from num_of_inputs being a block of code)
    #inputs: 
    #   1
    #   "freq"
    if num_of_inputs.kind == nnkStmtList:
        
        var 
            statement_counter = 0
            param_names_counter = 0

        for statement in num_of_inputs.children():
            if statement_counter == 0:
                if statement.kind != nnkIntLit:
                    error("Expected the number of inputs to be expressed by an integer literal value")
                
                num_of_inputs_VAL = int(statement.intVal)
                
                if num_of_inputs_VAL < 0:
                    error("Expected a positive number for inputs number")
        
                if num_of_inputs_VAL > max_inputs_outputs:
                    error("Exceeded maximum number of inputs, " & $max_inputs_outputs)
            else:
                if statement.kind != nnkStrLit:
                    error("Expected parameter name number " & $statement_counter & " to be a string literal value")
                
                let param_name = statement.strVal()

                for individualChar in param_name:
                    if not (individualChar in acceptedCharsForParamName):
                        error("Invalid character " & $individualChar & $ " in input name " & $param_name)
                
                param_names_string.add($param_name & ",")

                param_names_counter += 1

            statement_counter += 1

        #Remove trailing coma
        if param_names_string.len > 1:
            param_names_string = param_names_string[0..param_names_string.high-1]
        
        #Assign to node
        param_names_node = newLit(param_names_string)

        if param_names_counter > 0:
            if param_names_counter != num_of_inputs_VAL:
                error("Expected " & $num_of_inputs_VAL & " param names, got " & $param_names_counter)

            return quote do: 
                const 
                    omni_inputs {.inject.} = `num_of_inputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to insert variable from macro's scope
                    ugen_input_names {.inject.} = `param_names_node`  #It's possible to insert NimNodes directly in the code block
                
                generate_inputs_templates(`num_of_inputs_VAL`, 0)

                #Export to C
                proc get_omni_inputs() : int32 {.exportc: "get_omni_inputs".} =
                    return int32(omni_inputs)

                proc get_ugen_input_names() : ptr ptr cstring {.exportc: "get_ugen_input_names".} =
                    return cast[ptr ptr cstring](ugen_input_names)
        else:
            return quote do:
                const 
                    omni_inputs {.inject.} = `num_of_inputs_VAL`  
                    ugen_input_names {.inject.} = "__NO_PARAM_NAMES__"

                generate_inputs_templates(`num_of_inputs_VAL`, 0)

                #Export to C
                proc get_omni_inputs() : int32 {.exportc: "get_omni_inputs".} =
                    return int32(omni_inputs)

                proc get_ugen_input_names() : ptr cchar {.exportc: "get_ugen_input_names".} =
                    return cast[ptr cchar](ugen_input_names)

    #The standard form (derived by using num_of_inputs as int literal, and successive param_names as varargs[untyped]):
    #inputs 1, "freq"  OR inputs(1, "freq")
    else:

        #Must be an int literal
        if num_of_inputs.kind != nnkIntLit: #Just as the expectKind proc
            error("Expected the number of inputs to be expressed by an integer literal value")
        
        num_of_inputs_VAL = int(num_of_inputs.intVal)     #Actual value of the int literal

        if num_of_inputs_VAL < 0:
            error("Expected a positive number for inputs number")

        if num_of_inputs_VAL > max_inputs_outputs:
            error("Exceeded maximum number of inputs, " & $max_inputs_outputs)
        
        #Check for correct length of param names
        if len(param_names) > 0:
            if len(param_names) != num_of_inputs_VAL:
                error("Expected " & $num_of_inputs_VAL & " param names, got " & $(len(param_names)))
            
            #Check if all param names are string literal values
            for index, param_name_var in param_names:
                if param_name_var.kind != nnkStrLit:
                    error("Expected parameter name number " & $(index + 1) & " to be a string literal value")
                
                #Add literal string value to the nnkBracket NimNode
                let param_name = param_name_var.strVal()

                for individualChar in param_name:
                    if not (individualChar in acceptedCharsForParamName):
                        error("Invalid character " & $individualChar & $ " in input name " & $param_name)
                
                param_names_string.add($param_name & ",")
            
            #Remove trailing coma
            if param_names_string.len > 1:
                param_names_string = param_names_string[0..param_names_string.high-1]
            
            #Assign to node
            param_names_node = newLit(param_names_string)
            
            #Actual return statement: a valid NimNode wrapped in the "quote do:" syntax.
            return quote do: 
                const 
                    omni_inputs {.inject.} = `num_of_inputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to insert variable from macro's scope
                    ugen_input_names {.inject.} = `param_names_node`  #It's possible to insert NimNodes directly in the code block

                generate_inputs_templates(`num_of_inputs_VAL`, 0)

                #Export to C
                proc get_omni_inputs() : int32 {.exportc: "get_omni_inputs".} =
                    return int32(omni_inputs)

                proc get_ugen_input_names() : ptr char {.exportc: "get_ugen_input_names".} =
                    return cast[ptr char](ugen_input_names)
        else:
            return quote do:
                const 
                    omni_inputs {.inject.} = `num_of_inputs_VAL` 
                    ugen_input_names {.inject.} = "__NO_PARAM_NAMES__"

                generate_inputs_templates(`num_of_inputs_VAL`, 0)

                #Export to C
                proc get_omni_inputs() : int32 {.exportc: "get_omni_inputs".} =
                    return int32(omni_inputs)

                proc get_ugen_input_names() : ptr cchar {.exportc: "get_ugen_input_names".} =
                    return cast[ptr cchar](ugen_input_names)


#The block form (derived from using num_of_outputs as int literal, and param_names as a code block.):
#outputs 1:
#   "freq"
macro outs*(num_of_outputs : untyped, param_names : untyped) : untyped =
    
    var 
        num_of_outputs_VAL : int
        param_names_string : string = ""
        param_names_node : NimNode

    let param_names_kind = param_names.kind

    #Must be an int literal
    if num_of_outputs.kind != nnkIntLit: #Just as the expectKind proc
        error("Expected the number of outputs to be expressed by an integer literal value")

    if param_names_kind != nnkStmtList and param_names_kind != nnkStrLit:
        error("Expected a block statement after the number of outputs")
    
    num_of_outputs_VAL = int(num_of_outputs.intVal)     #Actual value of the int literal

    if num_of_outputs_VAL < 0:
        error("Expected a positive number for outputs number")
    
    if num_of_outputs_VAL > max_inputs_outputs:
        error("Exceeded maximum number of outputs, " & $max_inputs_outputs)

    var statement_counter = 0

    #This is for the outputs 1, "freq" case... output 2, "freq", "stmt" is covered in the other macro
    if param_names_kind == nnkStrLit:
        let param_name = param_names.strVal()
        
        for individualChar in param_name:
            if not (individualChar in acceptedCharsForParamName):
                error("Invalid character " & $individualChar & $ " in output name " & $param_name)
        
        param_names_string.add($param_name & ",")
        statement_counter = 1

    #Normal block case
    else:
        for statement in param_names.children():
            if statement.kind != nnkStrLit:
                error("Expected parameter name number " & $(statement_counter + 1) & " to be a string literal value")
            
            let param_name = statement.strVal()

            for individualChar in param_name:
                if not (individualChar in acceptedCharsForParamName):
                    error("Invalid character " & $individualChar & $ " in output name " & $param_name)
            
            param_names_string.add($param_name & ",")
            statement_counter += 1

    #Remove trailing coma
    if param_names_string.len > 1:
        param_names_string = param_names_string[0..param_names_string.high-1]
    
    #Assign to node
    param_names_node = newLit(param_names_string)
    
    if statement_counter != num_of_outputs_VAL:
        error("Expected " & $num_of_outputs_VAL & " param names, got " & $statement_counter)

    return quote do: 
        const 
            omni_outputs {.inject.} = `num_of_outputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to outsert variable from macro's scope
            ugen_output_names {.inject.} = `param_names_node`  #It's possible to outsert NimNodes directly in the code block 
        
        #For now, only keep the template for ar out, generated before sample block
        #generate_outputs_templates(`num_of_outputs_VAL`, 0)
        
        #Export to C
        proc get_omni_outputs() : int32 {.exportc: "get_omni_outputs".} =
            return int32(omni_outputs)

        proc get_ugen_output_names() : ptr cchar {.exportc: "get_ugen_output_names".} =
            return cast[ptr cchar](ugen_output_names)

macro outs*(num_of_outputs : untyped, param_names : varargs[untyped]) : untyped = 
    
    var 
        num_of_outputs_VAL : int
        param_names_string : string = ""
        param_names_node : NimNode

    #The other block form (derived from num_of_outputs being a block of code)
    #outputs: 
    #   1
    #   "freq"
    if num_of_outputs.kind == nnkStmtList:
        
        var 
            statement_counter = 0
            param_names_counter = 0

        for statement in num_of_outputs.children():
            if statement_counter == 0:
                if statement.kind != nnkIntLit:
                    error("Expected the number of outputs to be expressed by an integer literal value")
                
                num_of_outputs_VAL = int(statement.intVal)
                
                if num_of_outputs_VAL < 0:
                    error("Expected a positive number for outputs number")
        
                if num_of_outputs_VAL > max_inputs_outputs:
                    error("Exceeded maximum number of outputs, " & $max_inputs_outputs)
            else:
                if statement.kind != nnkStrLit:
                    error("Expected parameter name number " & $statement_counter & " to be a string literal value")
                
                let param_name = statement.strVal()

                for individualChar in param_name:
                    if not (individualChar in acceptedCharsForParamName):
                        error("Invalid character " & $individualChar & $ " in output name " & $param_name)
                
                param_names_string.add($param_name & ",")

                param_names_counter += 1

            statement_counter += 1

        #Remove trailing coma
        if param_names_string.len > 1:
            param_names_string = param_names_string[0..param_names_string.high-1]
        
        #Assign to node
        param_names_node = newLit(param_names_string)

        if param_names_counter > 0:
            if param_names_counter != num_of_outputs_VAL:
                error("Expected " & $num_of_outputs_VAL & " param names, got " & $param_names_counter)

            return quote do: 
                const 
                    omni_outputs {.inject.} = `num_of_outputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to outsert variable from macro's scope
                    ugen_output_names {.inject.} = `param_names_node`  #It's possible to outsert NimNodes directly in the code block
                
                #For now, only keep the template for ar out, generated before sample block
                #generate_outputs_templates(`num_of_outputs_VAL`, 0)

                #Export to C
                proc get_omni_outputs() : int32 {.exportc: "get_omni_outputs".} =
                    return int32(omni_outputs)

                proc get_ugen_output_names() : ptr ptr cstring {.exportc: "get_ugen_output_names".} =
                    return cast[ptr ptr cstring](ugen_output_names)
        else:
            return quote do:
                const 
                    omni_outputs {.inject.} = `num_of_outputs_VAL`  
                    ugen_output_names {.inject.} = "__NO_PARAM_NAMES__"

                #For now, only keep the template for ar out, generated before sample block
                #generate_outputs_templates(`num_of_outputs_VAL`, 0)

                #Export to C
                proc get_omni_outputs() : int32 {.exportc: "get_omni_outputs".} =
                    return int32(omni_outputs)

                proc get_ugen_output_names() : ptr cchar {.exportc: "get_ugen_output_names".} =
                    return cast[ptr cchar](ugen_output_names)

    #The standard form (derived by using num_of_outputs as int literal, and successive param_names as varargs[untyped]):
    #outputs 1, "freq"  OR outputs(1, "freq")
    else:

        #Must be an int literal
        if num_of_outputs.kind != nnkIntLit: #Just as the expectKind proc
            error("Expected the number of outputs to be expressed by an integer literal value")
        
        num_of_outputs_VAL = int(num_of_outputs.intVal)     #Actual value of the int literal

        if num_of_outputs_VAL < 0:
            error("Expected a positive number for outputs number")

        if num_of_outputs_VAL > max_inputs_outputs:
            error("Exceeded maximum number of outputs, " & $max_inputs_outputs)
        
        #Check for correct length of param names
        if len(param_names) > 0:
            if len(param_names) != num_of_outputs_VAL:
                error("Expected " & $num_of_outputs_VAL & " param names, got " & $(len(param_names)))
            
            #Check if all param names are string literal values
            for index, param_name_var in param_names:
                if param_name_var.kind != nnkStrLit:
                    error("Expected parameter name number " & $(index + 1) & " to be a string literal value")
                
                #Add literal string value to the nnkBracket NimNode
                let param_name = param_name_var.strVal()

                for individualChar in param_name:
                    if not (individualChar in acceptedCharsForParamName):
                        error("Invalid character " & $individualChar & $ " in output name " & $param_name)
                
                param_names_string.add($param_name & ",")
            
            #Remove trailing coma
            if param_names_string.len > 1:
                param_names_string = param_names_string[0..param_names_string.high-1]
            
            #Assign to node
            param_names_node = newLit(param_names_string)
            
            #Actual return statement: a valid NimNode wrapped in the "quote do:" syntax.
            return quote do: 
                const 
                    omni_outputs {.inject.} = `num_of_outputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to outsert variable from macro's scope
                    ugen_output_names {.inject.} = `param_names_node`  #It's possible to outsert NimNodes directly in the code block

                #For now, only keep the template for ar out, generated before sample block
                #generate_outputs_templates(`num_of_outputs_VAL`, 0)

                #Export to C
                proc get_omni_outputs() : int32 {.exportc: "get_omni_outputs".} =
                    return int32(omni_outputs)

                proc get_ugen_output_names() : ptr char {.exportc: "get_ugen_output_names".} =
                    return cast[ptr char](ugen_output_names)
        else:
            return quote do:
                const 
                    omni_outputs {.inject.} = `num_of_outputs_VAL` 
                    ugen_output_names {.inject.} = "__NO_PARAM_NAMES__"

                #For now, only keep the template for ar out, generated before sample block
                #generate_outputs_templates(`num_of_outputs_VAL`, 0)

                #Export to C
                proc get_omni_outputs() : int32 {.exportc: "get_omni_outputs".} =
                    return int32(omni_outputs)

                proc get_ugen_output_names() : ptr cchar {.exportc: "get_ugen_output_names".} =
                    return cast[ptr cchar](ugen_output_names)