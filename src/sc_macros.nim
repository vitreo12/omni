#Here I should just import all the macros functions that I am using, to not compile the entire macros module.
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
            ugen_inputs {.inject.} = `num_of_inputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to insert variable from macro's scope
            ugen_input_names {.inject.} = `param_names_node`  #It's possible to insert NimNodes directly in the code block 
        
        generate_inputs_templates(`num_of_inputs_VAL`, 0)
        
        #Export to C
        proc get_ugen_inputs() : int32 {.exportc: "get_ugen_inputs".} =
            return int32(ugen_inputs)

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
                    ugen_inputs {.inject.} = `num_of_inputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to insert variable from macro's scope
                    ugen_input_names {.inject.} = `param_names_node`  #It's possible to insert NimNodes directly in the code block
                
                generate_inputs_templates(`num_of_inputs_VAL`, 0)

                #Export to C
                proc get_ugen_inputs() : int32 {.exportc: "get_ugen_inputs".} =
                    return int32(ugen_inputs)

                proc get_ugen_input_names() : ptr ptr cstring {.exportc: "get_ugen_input_names".} =
                    return cast[ptr ptr cstring](ugen_input_names)
        else:
            return quote do:
                const 
                    ugen_inputs {.inject.} = `num_of_inputs_VAL`  
                    ugen_input_names {.inject.} = "__NO_PARAM_NAMES__"

                generate_inputs_templates(`num_of_inputs_VAL`, 0)

                #Export to C
                proc get_ugen_inputs() : int32 {.exportc: "get_ugen_inputs".} =
                    return int32(ugen_inputs)

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
                    ugen_inputs {.inject.} = `num_of_inputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to insert variable from macro's scope
                    ugen_input_names {.inject.} = `param_names_node`  #It's possible to insert NimNodes directly in the code block

                generate_inputs_templates(`num_of_inputs_VAL`, 0)

                #Export to C
                proc get_ugen_inputs() : int32 {.exportc: "get_ugen_inputs".} =
                    return int32(ugen_inputs)

                proc get_ugen_input_names() : ptr char {.exportc: "get_ugen_input_names".} =
                    return cast[ptr char](ugen_input_names)
        else:
            return quote do:
                const 
                    ugen_inputs {.inject.} = `num_of_inputs_VAL` 
                    ugen_input_names {.inject.} = "__NO_PARAM_NAMES__"

                generate_inputs_templates(`num_of_inputs_VAL`, 0)

                #Export to C
                proc get_ugen_inputs() : int32 {.exportc: "get_ugen_inputs".} =
                    return int32(ugen_inputs)

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
            ugen_outputs {.inject.} = `num_of_outputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to outsert variable from macro's scope
            ugen_output_names {.inject.} = `param_names_node`  #It's possible to outsert NimNodes directly in the code block 
        
        #For now, only keep the template for ar out, generated before sample block
        #generate_outputs_templates(`num_of_outputs_VAL`, 0)
        
        #Export to C
        proc get_ugen_outputs() : int32 {.exportc: "get_ugen_outputs".} =
            return int32(ugen_outputs)

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
                    ugen_outputs {.inject.} = `num_of_outputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to outsert variable from macro's scope
                    ugen_output_names {.inject.} = `param_names_node`  #It's possible to outsert NimNodes directly in the code block
                
                #For now, only keep the template for ar out, generated before sample block
                #generate_outputs_templates(`num_of_outputs_VAL`, 0)

                #Export to C
                proc get_ugen_outputs() : int32 {.exportc: "get_ugen_outputs".} =
                    return int32(ugen_outputs)

                proc get_ugen_output_names() : ptr ptr cstring {.exportc: "get_ugen_output_names".} =
                    return cast[ptr ptr cstring](ugen_output_names)
        else:
            return quote do:
                const 
                    ugen_outputs {.inject.} = `num_of_outputs_VAL`  
                    ugen_output_names {.inject.} = "__NO_PARAM_NAMES__"

                #For now, only keep the template for ar out, generated before sample block
                #generate_outputs_templates(`num_of_outputs_VAL`, 0)

                #Export to C
                proc get_ugen_outputs() : int32 {.exportc: "get_ugen_outputs".} =
                    return int32(ugen_outputs)

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
                    ugen_outputs {.inject.} = `num_of_outputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to outsert variable from macro's scope
                    ugen_output_names {.inject.} = `param_names_node`  #It's possible to outsert NimNodes directly in the code block

                #For now, only keep the template for ar out, generated before sample block
                #generate_outputs_templates(`num_of_outputs_VAL`, 0)

                #Export to C
                proc get_ugen_outputs() : int32 {.exportc: "get_ugen_outputs".} =
                    return int32(ugen_outputs)

                proc get_ugen_output_names() : ptr char {.exportc: "get_ugen_output_names".} =
                    return cast[ptr char](ugen_output_names)
        else:
            return quote do:
                const 
                    ugen_outputs {.inject.} = `num_of_outputs_VAL` 
                    ugen_output_names {.inject.} = "__NO_PARAM_NAMES__"

                #For now, only keep the template for ar out, generated before sample block
                #generate_outputs_templates(`num_of_outputs_VAL`, 0)

                #Export to C
                proc get_ugen_outputs() : int32 {.exportc: "get_ugen_outputs".} =
                    return int32(ugen_outputs)

                proc get_ugen_output_names() : ptr cchar {.exportc: "get_ugen_output_names".} =
                    return cast[ptr cchar](ugen_output_names)


#All the other things needed to create the proc destructor are passed in as untyped directly from the return statement of "struct"
macro defineDestructor*(obj : typed, ptr_name : untyped, generics : untyped, ptr_bracket_expr : untyped, var_names : untyped, is_ugen_destructor : bool) =
    var 
        final_stmt    = nnkStmtList.newTree()
        proc_def      : NimNode
        init_formal_params = nnkFormalParams.newTree(newIdentNode("void"))
        proc_body     = nnkStmtList.newTree()
            
        var_obj_positions : seq[int]
        ptr_name_str : string
        
    let is_ugen_destructor_bool = is_ugen_destructor.boolVal()

    if is_ugen_destructor_bool == true:
        #Full proc definition for UGenDestructor. The result is: proc UGenDestructor*(ugen : ptr UGen) : void {.exportc: "UGenDestructor".} 
        proc_def = nnkProcDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("UGenDestructor")
            ),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("void"),
                nnkIdentDefs.newTree(
                    newIdentNode("obj_void"),
                    newIdentNode("pointer"),
                    newEmptyNode()
                )
            ),
            nnkPragma.newTree(
                nnkExprColonExpr.newTree(
                    newIdentNode("exportc"),
                    newLit("UGenDestructor")
                )
            ),
            newEmptyNode()
        )
    else:
        #Just add proc destructor to proc def. Everything else will be added later
        proc_def = nnkProcDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("destructor")
            ),
            newEmptyNode(),
        )

        #Actual name
        ptr_name_str = ptr_name.strVal()

    let rec_list = getImpl(obj)[2][2]
    
    #Extract if there is a ptr SomeObject_obj in the fields of the type, to add it to destructor procedure.
    for index, ident_defs in rec_list:     
        for entry in ident_defs:

            var 
                var_number : int
                entry_impl : NimNode

            if entry.kind == nnkSym:
                entry_impl = getTypeImpl(entry)
            elif entry.kind == nnkBracketExpr:
                entry_impl = getTypeImpl(entry[0])
            elif entry.kind == nnkPtrTy:             #the case for UGen, where variables are stored as ptr Phasor_obj, instead of Phasor       
                entry_impl = entry
            else:
                continue 
            
            #It's a ptr to something. Check if it's a pointer to an "_obj"
            if entry_impl.kind == nnkPtrTy:
                
                #Inner statement of ptr, could be a symbol (no generics, just the name) or a bracket (generics) 
                let entry_inner = entry_impl[0]

                #non-generic
                if entry_inner.kind == nnkSym:
                    let entry_inner_str = entry_inner.strVal()
                    
                    #Found it! add the position in the definition to the seq
                    if entry_inner_str[len(entry_inner_str) - 4 .. len(entry_inner_str) - 1] == "_obj":
                        var_number = index
                        var_obj_positions.add(var_number)

                #generic
                elif entry_inner.kind == nnkBracketExpr:
                    let entry_inner_str = entry_inner[0].strVal()

                    #Found it! add the position in the definition to the seq
                    if entry_inner_str[len(entry_inner_str) - 4 .. len(entry_inner_str) - 1] == "_obj":
                        var_number = index
                        var_obj_positions.add(var_number)
    
    if is_ugen_destructor_bool == true:
        proc_body.add(
            nnkCommand.newTree(
                newIdentNode("print"),
                newLit("Calling UGen\'s destructor\n")
            ),
            nnkLetSection.newTree(
                nnkIdentDefs.newTree(
                    newIdentNode("obj"),
                    newEmptyNode(),
                    nnkCast.newTree(
                        nnkPtrTy.newTree(
                        newIdentNode("UGen")
                        ),
                        newIdentNode("obj_void")
                    )
                )
            )  
        )
    else:
        #Generics stuff to add to destructor function declaration
        if generics.len() > 0:
            proc_def.add(generics)
        else: #no generics
            proc_def.add(newEmptyNode())

        init_formal_params.add(
            nnkIdentDefs.newTree(
                newIdentNode("obj"),
                ptr_bracket_expr,
                newEmptyNode()
            )
        )

        proc_def.add(init_formal_params)
        proc_def.add(newEmptyNode())
        proc_def.add(newEmptyNode())

        proc_body.add(
            nnkCommand.newTree(
                newIdentNode("print"),
                newLit("Calling " & $ptr_name_str & "\'s destructor\n" )
            )   
        )
    
    if var_obj_positions.len() > 0:
        for var_index in var_obj_positions:
            proc_body.add(
                nnkCall.newTree(
                    newIdentNode("destructor"),
                    nnkDotExpr.newTree(
                        newIdentNode("obj"),
                        var_names[var_index]        #retrieve the correct name from the body of the struct
                    )
                )
            )
    
    #let obj_void = cast[pointer](obj)
    if is_ugen_destructor_bool == false:
        proc_body.add(
            nnkLetSection.newTree(
                nnkIdentDefs.newTree(
                    newIdentNode("obj_void"),
                    newEmptyNode(),
                    nnkCast.newTree(
                        newIdentNode("pointer"),
                        newIdentNode("obj")
                    )
                )
            )
        )

    proc_body.add(
        nnkIfStmt.newTree(
            nnkElifBranch.newTree(
                nnkPrefix.newTree(
                    newIdentNode("not"),
                    nnkCall.newTree(
                        nnkDotExpr.newTree(
                            newIdentNode("obj_void"),
                            newIdentNode("isNil")
                        )
                    )
                ),
                nnkStmtList.newTree(
                    nnkCall.newTree(
                        newIdentNode("rt_free"),
                        newIdentNode("obj_void")
                    )
                )
            )
        )
    )

    proc_def.add(proc_body)

    final_stmt.add(proc_def)

    #echo astGenRepr final_stmt

    return quote do:
        `final_stmt`
        
        
macro struct*(struct_name : untyped, code_block : untyped) : untyped =
    var 
        final_stmt_list = nnkStmtList.newTree()
        type_section    = nnkTypeSection.newTree()
        obj_type_def    = nnkTypeDef.newTree()      #the Phasor_obj block
        obj_ty          = nnkObjectTy.newTree()     #the body of the Phasor_obj   
        rec_list        = nnkRecList.newTree()      #the variable declaration section of Phasor_obj
        
        ptr_type_def    = nnkTypeDef.newTree()      #the Phasor = ptr Phasor_obj block
        ptr_ty          = nnkPtrTy.newTree()        #the ptr type expressing ptr Phasor_obj
        
        init_proc_def        = nnkProcDef.newTree()      #the init* function
        init_formal_params   = nnkFormalParams.newTree()
        init_fun_body        = nnkStmtList.newTree()

    obj_ty.add(newEmptyNode())
    obj_ty.add(newEmptyNode())
    
    var 
        obj_name : NimNode
        ptr_name : NimNode
        generics = nnkGenericParams.newTree()  #If generics are present in struct definition
        generics_proc_def = nnkGenericParams.newTree() #These are all the generics that will be set to be T : SomeNumber, instead of just T

        obj_bracket_expr : NimNode
        ptr_bracket_expr : NimNode

        var_names : seq[NimNode]
        var_types : seq[NimNode]
    
    #Using generics
    if struct_name.kind == nnkBracketExpr:
        obj_name = newIdentNode($(struct_name[0].strVal()) & "_obj")  #Phasor_obj
        ptr_name = struct_name[0]                                     #Phasor

        #If struct name doesn't start with capital letter, error out
        if not(ptr_name.strVal[0] in {'A'..'Z'}):
            error("struct \"" & $ptr_name & $ "\" must start with a capital letter")

        #NOTE THE DIFFERENCE BETWEEN obj_type_def here with generics and without, different number of newEmptyNode()
        #Add name to obj_type_def (with asterisk, in case of supporting modules in the future)
        obj_type_def.add(nnkPostfix.newTree(
                newIdentNode("*"),
                obj_name
            )
        )

        #NOTE THE DIFFERENCE BETWEEN ptr_type_def here with generics and without, different number of newEmptyNode()
        #Add name to ptr_type_def (with asterisk, in case of supporting modules in the future)
        ptr_type_def.add(nnkPostfix.newTree(
                newIdentNode("*"),
                ptr_name
            )
        )

        #The name of the function with the asterisk, in case of supporting modules in the future
        #Note that init_proc_def for generics has just one newEmptyNode()
        init_proc_def.add(nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("init")
            ),
            newEmptyNode()
        )

        #Initialize them to be bracket expressions
        obj_bracket_expr = nnkBracketExpr.newTree()
        ptr_bracket_expr = nnkBracketExpr.newTree()

        #Add the "Phasor_obj" and "Phasor" names to brackets
        obj_bracket_expr.add(obj_name)
        ptr_bracket_expr.add(ptr_name)

        for index, child in struct_name:
            if index == 0:
                continue
            else:
                var 
                    generic_proc = nnkIdentDefs.newTree()
                    generic_proc_proc_def = nnkIdentDefs.newTree()
                    
                #If singular [T]
                if child.len() == 0:
                    ##Also add the name of the generic to the Phasor_obj[T, Y...]
                    obj_bracket_expr.add(child)

                    #Also add the name of the generic to the Phasor[T, Y...]
                    ptr_bracket_expr.add(child)

                    generic_proc.add(child)
                    generic_proc_proc_def.add(child)

                    generic_proc.add(newEmptyNode())
                    generic_proc_proc_def.add(newIdentNode("SomeNumber"))  #add ": SomeNumber" to the generic type

                    generic_proc.add(newEmptyNode())
                    generic_proc_proc_def.add(newEmptyNode())

                    generics.add(generic_proc)
                    generics_proc_def.add(generic_proc_proc_def)

                #If [T : SomeFloat or SomeInteger... etc...]
                else:
                    error($ptr_name.strVal() & $ "\'s generic type \"" & $(child[0].strVal()) & "\" contains subtypes. These are not supported. Struct's generic types are defaulted to only be SomeNumber.")

                    #This works, but it's better to not to use it.
                    #[ #All the generics (including the "or" infixes, etc...)
                    for inner_index, inner_child in child:

                        #Add the name of the generics to a table, to be used for ptr
                        if inner_index == 0:
                            obj_bracket_expr.add(inner_child)
                            ptr_bracket_expr.add(inner_child)
                        
                        generic_proc.add(inner_child)
                    
                    generic_proc.add(newEmptyNode())
                    generics.add(generic_proc) ]#
            
        #Add generics to obj type
        obj_type_def.add(generics)

        #Add generics to ptr type
        ptr_type_def.add(generics)

        #Add generics to proc definition. (proc init*[T : SomeNumber, Y : SomeNumber]...) These will have added the ": SomeNumber" on each generic.
        init_proc_def.add(generics_proc_def)
        
        #Add the Phasor_obj[T, Y] to ptr_ty, for object that the pointer points at.
        ptr_ty.add(obj_bracket_expr)

    #No generics, just name of struct
    elif struct_name.kind == nnkIdent:
        obj_name = newIdentNode($(struct_name) & "_obj")              #Phasor_obj
        ptr_name = struct_name                                        #Phasor

        #If struct name doesn't start with capital letter, error out
        if not(ptr_name.strVal[0] in {'A'..'Z'}):
            error("struct \"" & $ptr_name & $ "\" must start with a capital letter")
        
        #Add name to obj_type_def (with asterisk, in case of supporting modules in the future)
        obj_type_def.add(nnkPostfix.newTree(
                newIdentNode("*"),
                obj_name
            ),
            newEmptyNode()
        )

        #Add name to ptr_type_def (with asterisk, in case of supporting modules in the future)
        ptr_type_def.add(nnkPostfix.newTree(
                newIdentNode("*"),
                ptr_name
            ),
            newEmptyNode()
        )

        #The name of the function with the asterisk, in case of supporting modules in the future
        init_proc_def.add(nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("init")
            ),
            newEmptyNode(),
            newEmptyNode()
        )

        #Add the Phasor_obj[T, Y] to ptr_ty, for object that the pointer points at.
        ptr_ty.add(obj_name)

        #When not using generics, the sections where the bracket generic expression is used are just the normal name of the type
        obj_bracket_expr = obj_name
        ptr_bracket_expr = ptr_name

    for code_stmt in code_block:
        #Have some better error checking and printing here
        if code_stmt.len != 2 or code_stmt.kind != nnkCall or code_stmt[0].kind != nnkIdent or code_stmt[1].kind != nnkStmtList or code_stmt[1][0].kind != nnkIdent:
            
            #Needed for generics in body of struct
            if code_stmt[1][0].kind != nnkBracketExpr:
                error("\"" & $ptr_name & "\": " & "Invalid struct body")
        
        var 
            var_name = code_stmt[0]
            var_type = code_stmt[1][0]
            new_decl = nnkIdentDefs.newTree()

        var_names.add(var_name)
        var_types.add(var_type)

        new_decl.add(var_name)
        new_decl.add(var_type)
        new_decl.add(newEmptyNode())

        rec_list.add(new_decl)
    
    ####################################
    # Add all things related to object #
    ####################################

    #Add var : type declarations to obj declaration
    obj_ty.add(rec_list)
    
    #Add the obj declaration (the nnkObjectTy) to the type declaration
    obj_type_def.add(obj_ty)
    
    #Add the type declaration of Phasor_obj to the type section
    type_section.add(obj_type_def)
    
    #####################################
    # Add all things related to pointer #
    #####################################
    
    #Add the ptr_ty inners to ptr_type_def
    ptr_type_def.add(ptr_ty)
    
    #Add the type declaration of Phasor to type section
    type_section.add(ptr_type_def)

    #Add the whole type section to result
    final_stmt_list.add(type_section)
    
    ################
    # INIT SECTION #
    ################
    
    #Add Phasor[T, Y] return type
    init_formal_params.add(ptr_bracket_expr)

    #Add obj_type : typedesc[Phasor[T, Y]]
    init_formal_params.add(nnkIdentDefs.newTree(
            newIdentNode("obj_type"),
            nnkBracketExpr.newTree(
                newIdentNode("typedesc"),
                ptr_bracket_expr
            ),
            newEmptyNode()
        )   
    )

    #Add args to function
    for index, var_name in var_names:
        var new_arg = nnkIdentDefs.newTree(
            var_name,
            var_types[index],
            newEmptyNode()
        )

        init_formal_params.add(new_arg)

    init_proc_def.add(init_formal_params)

    init_proc_def.add(newEmptyNode())
    init_proc_def.add(newEmptyNode())

    #Cast and rtalloc operators
    init_fun_body.add(
        nnkAsgn.newTree(
            newIdentNode("result"),
            nnkCast.newTree(
                ptr_bracket_expr,
                nnkCall.newTree(
                        newIdentNode("rt_alloc"),
                        nnkCast.newTree(
                            newIdentNode("culong"),
                                nnkCall.newTree(
                                newIdentNode("sizeof"),
                                obj_bracket_expr
                        )
                    )                 
                )
            )
        )
    )

    #Add result.phase = phase, etc..
    for index, var_name in var_names:
        init_fun_body.add(
            nnkAsgn.newTree(
                nnkDotExpr.newTree(
                    newIdentNode("result"),
                    var_name
                ),
                var_name
            )
        )
    
    #Add the function body to the proc declaration
    init_proc_def.add(init_fun_body)
    
    #Add everything to result
    final_stmt_list.add(init_proc_def)
    
    #If using result, it was bugging. Needs to be returned like this to be working properly. don't know why.
    return quote do:
        `final_stmt_list`
        
        #defining the destructor requires to use another macro with a typed argument for the type, in order to inspect its fields.

        #generics or generics_pproc_def here? it should be the same, as long as object was constructed with generics_proc_def (which not only
        #contains "[T, Y]", but "[T : SomeNumber, Y : SomeNumber]"). These are not necessary for a generic destructor. It would work on them too.
        defineDestructor(`obj_name`, `ptr_name`, `generics`, `ptr_bracket_expr`, `var_names`, false)

#being the argument typed, the code_block is semantically executed after parsing, making it to return the correct result out of the "new" statement
macro executeNewStatementAndBuildUGenObjectType(code_block : typed) : untyped =    
    discard
    
    #let call_to_new_macro = code_block.last()

    #code_block.astGenRepr.echo

    #return quote do:
    #    `call_to_new_macro`

macro debug*() =
    echo "To be added"

macro constructor*(code_block : untyped) =

    #new: ... syntax could be built by parsing directly this block of code,
    #and construct the types by looking at IntLits, StrLits, and ObjConstr (for custom objects)
    #echo treeRepr code_block

    #ALSO, I could have my own parser that looks for assignment NimNodes, and add the var names to a seq[NimNode] (with nnkIdents).
    #On first occurance of a name, add a "var" prefix. (Or a "let", without allowing the changing of the values.)
    #In the case of using the same method in the "perform" macro, always prepend the "var".
    #HOWEVER, this would slow parsing and compilation times. Is it worth it?

    var 
        #They both are nnkIdentNodes
        let_declarations : seq[NimNode]
        var_declarations : seq[NimNode]

        templates_for_perform_var_declarations     = nnkStmtList.newTree()
        templates_for_constructor_var_declarations = nnkStmtList.newTree()
        templates_for_constructor_let_declarations = nnkStmtList.newTree()

        empty_var_statements : seq[NimNode]
        call_to_new_macro : NimNode
        final_var_names = nnkBracket.newTree()
        constructor_body : NimNode

    #Look if "new" macro call is the last statement in the block.
    if code_block.last().kind != nnkCall and code_block.last().kind != nnkCommand:
        error("Last constructor statement must be a call to \"new\".")
    elif code_block.last()[0].strVal() != "new":
        error("Last constructor statement must be a call to \"new\".")

    call_to_new_macro = code_block.last()

    #First element of the call_to_new_macro ([0]) is the name of the calling function (Ident("new"))
    #Second element - unpacked here - is the kind of syntax used to call the macro. It can either be just
    #a list of idents - which is the case for the normal "new(a, b)" syntax - or either a nnkStmtList - for the
    #"new : \n a \n b" syntax - or a nnkCommand list - for the "new a b" syntax.
    let type_of_syntax = call_to_new_macro[1]

    var temp_call_to_new_macro = nnkCall.newTree(newIdentNode("new"))

    #[
        nnkStmtList is:
        new:
            a
            b

        nnkCommand is:
        new a b

        Format them both to be the same way as the normal new(a, b) call.
    ]#
    if type_of_syntax.kind == nnkStmtList or type_of_syntax.kind == nnkCommand:
        
        #nnkCommand can recursively represent elements in nnkCommand trees. Unpack all the nnkIdents and append them to the temp_call_to_new_macro variable.
        proc recursive_unpack_of_commands(input : NimNode) : void =    
            for input_children in input:
                if input_children.kind == nnkStmtList or input_children.kind == nnkCommand:
                    recursive_unpack_of_commands(input_children)
                else:
                    temp_call_to_new_macro.add(input_children)

        #Unpack the elements and add them to temp_call_to_new_macro, which is a nnkCall tree.
        recursive_unpack_of_commands(type_of_syntax)
        
        #Substitute the original code block with the new one.
        call_to_new_macro = temp_call_to_new_macro

    #[
        REDUCE ALL THESE FOR LOOPS IN A BETTER WAY!!
    ]#

    #Loop over all the statements in code_block, looking for "var" and "let" declarations
    for outer_index, statement in code_block:
        #var statements
        if statement.kind == nnkVarSection:
            for inner_index, var_declaration in statement:
                let 
                    var_declaration_name = var_declaration[0]
                    new_var_declaration = newIdentNode($(var_declaration[0].strVal()) & "_var")

                #Add the ORIGINAL ident name to the array, modifying its name to be "variableName_var"
                var_declarations.add(var_declaration_name)

                #Then, modify the field in the code_block to be "variableName_var"
                code_block[outer_index][inner_index][0] = new_var_declaration
                
                #Found one! add the sym to seq. It's a nnkIdent.
                if var_declaration[2].kind == nnkEmpty:
                    empty_var_statements.add(var_declaration_name)

                #[
                    RESULT:
                    template phase() : untyped {.dirty.} =    #The untyped here is fundamental to make this act like a normal text replacement.
                        phase_var
                ]#                
                #Construct a template that replaces the "variableName" in code with "variableName_var", to be used in constructor for correct namings
                let constructor_var_template = nnkTemplateDef.newTree(
                    var_declaration_name,                       #original name
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
                        new_var_declaration                #new name
                    )
                )

                templates_for_constructor_var_declarations.add(constructor_var_template)
        
        #let statements
        elif statement.kind == nnkLetSection:
            for inner_index, let_declaration in statement:
                let 
                    let_declaration_name = let_declaration[0]
                    new_let_declaration = newIdentNode($(let_declaration_name.strVal()) & "_let")

                #Add the ORIGINAL ident name to the array
                let_declarations.add(let_declaration_name)

                #Then, modify the field in the code_block to be "variableName_let"
                code_block[outer_index][inner_index][0] = new_let_declaration

                #[
                    RESULT:
                    template phase() : untyped {.dirty.} =    #The untyped here is fundamental to make this act like a normal text replacement.
                        phase_let
                ]#                
                #Construct a template that replaces the "variableName" in code with "variableName_let", to be used in constructor for correct namings
                let constructor_let_template = nnkTemplateDef.newTree(
                    let_declaration_name,                       #original name
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
                        new_let_declaration                #new name
                    )
                )

                templates_for_constructor_let_declarations.add(constructor_let_template)
    
    #Check the variables that are passed to call_to_new_macro
    for index, new_macro_var_name in call_to_new_macro:               #loop over every passed in variables to the "new" call
        for empty_var_statement in empty_var_statements:
            #Trying to pass in an unitialized "var" variable
            if empty_var_statement == new_macro_var_name: #They both are nnkIdents. They can be compared.
                error("\"" & $(empty_var_statement.strVal()) & "\" is a non-initialized variable. It can't be an input to a \"new\" statement.")
        
        #Check if any of the var_declarations are inputs to the "new" macro. If so, append their variable name with "_var"
        for var_declaration in var_declarations:
            if var_declaration == new_macro_var_name:
                #Replace the input to the "new" macro to be "variableName_var"
                let new_var_declaration = newIdentNode($(var_declaration.strVal()) & "_var")
                
                #Replace the name directly in the call to the "new" macro
                call_to_new_macro[index] = new_var_declaration

                #[
                    RESULT:
                    template phase() : untyped {.dirty.} =    #The untyped here is fundamental to make this act like a normal text replacement.
                        phase_var[]
                ]#                
                #Construct a template that replaces the "variableName" in code with "variableName_var[]", to access the field directly in perform.
                let perform_var_template = nnkTemplateDef.newTree(
                    var_declaration,                            #original name
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
                        nnkBracketExpr.newTree(
                            new_var_declaration                 #new name
                        )
                    )
                )

                templates_for_perform_var_declarations.add(perform_var_template)
        
        #Check if any of the var_declarations are inputs to the "new" macro. If so, append their variable name with "_let"
        for let_declaration in let_declarations:
            if let_declaration == new_macro_var_name:
                #Replace the input to the "new" macro to be "variableName_let"
                let new_let_declaration = newIdentNode($(let_declaration.strVal()) & "_let")

                #Replace the name directly in the call to the "new" macro
                call_to_new_macro[index] = new_let_declaration

    #echo astGenRepr templates_for_perform_var_declarations

    #First statement of the constructor is the allocation of the "ugen" variable. 
    #The allocation should be done using SC's RTAlloc functions. For testing, use alloc0 for now.
    #[
        dumpAstGen:
            var ugen: ptr UGen = cast[ptr UGen](alloc0(sizeof(UGen)))
    ]#
    constructor_body = nnkStmtList.newTree(
        nnkVarSection.newTree(
            nnkIdentDefs.newTree(
                newIdentNode("ugen"),
                nnkPtrTy.newTree(
                    newIdentNode("UGen")
                ),
                nnkCast.newTree(
                    nnkPtrTy.newTree(
                        newIdentNode("UGen")
                    ),
                    nnkCall.newTree(
                        newIdentNode("rt_alloc"),
                        nnkCast.newTree(
                            newIdentNode("culong"),
                                nnkCall.newTree(
                                newIdentNode("sizeof"),
                                newIdentNode("UGen")
                            )
                        )                 
                    )
                )
            )
        )
    )

    #build the ugen.a = a, ugen.b = b constructs
    for index, var_name in call_to_new_macro:
        
        #In case user is trying to not insert a variable with name in, like "new(1)"
        if var_name.kind != nnkIdent:
            error("Trying to use a literal value at index " & $index & " of the \"new\" statement. Use a named variable instead.")
        
        #Standard case, an nnkIdent with the variable name
        if index > 0: 

            let var_name_str = var_name.strVal()

            let ugen_asgn_stmt = nnkAsgn.newTree(
                nnkDotExpr.newTree(
                    newIdentNode("ugen"),
                    newIdentNode(var_name_str)  #symbol name (ugen.$name)
                ),
                newIdentNode(var_name_str)      #symbol name ($name)
            )

            constructor_body.add(ugen_asgn_stmt)

            final_var_names.add(newIdentNode(var_name_str))

        #First ident == "new"
        else: 
            continue
    
    #Also add ugen.samplerate_let = samplerate
    constructor_body.add(
        nnkAsgn.newTree(
            nnkDotExpr.newTree(
                newIdentNode("ugen"),
                newIdentNode("samplerate_let")
            ),
            newIdentNode("samplerate")      
        )
    )
    
    #Prepend to the code block the declaration of the templates for name mangling, in order for the typed block in the "executeNewStatementAndBuildUGenObjectType" macro to correctly mangle the "_var" and "_let" named variables, before sending the result to the "new" macro
    let code_block_with_var_let_templates_and_call_to_new_macro = nnkStmtList.newTree(
        templates_for_constructor_var_declarations,
        templates_for_constructor_let_declarations,
        code_block.copy()
    )
    
    #remove the call to "new" macro from code_block. It will then be just the body of constructor function.
    code_block.del(code_block.len() - 1)

    result = quote do:
        #Template that, when called, will generate the template for the name mangling of "_var" variables in the UGenPerform proc.
        #This is a fast way of passing the `templates_for_perform_var_declarations` block of code over another section of the code, by simply evaluating the "generateTemplatesForPerformVarDeclarations()" macro
        template generateTemplatesForPerformVarDeclarations() : untyped {.dirty.} =
            `templates_for_perform_var_declarations`
                
        #Trick the compiler of the existence of bufsize(), samplerate() and ins_Nim() before sending the block to semantic checking.
        #Using templates (instead of let statement) because of the Buffer.samplerate function, which the compiler won't pick correctt.y
        template bufsize()    : untyped {.dirty.} = 0
        template samplerate() : untyped {.dirty.} = 0
        template ins_Nim()    : untyped {.dirty.} = cast[CFloatPtrPtr](0.0)

        #With a macro with typed argument, I can just pass in the block of code and it is semantically evaluated. I just need then to extract the result of the "new" statement
        executeNewStatementAndBuildUGenObjectType(`code_block_with_var_let_templates_and_call_to_new_macro`)
        
        #Actual constructor that returns a UGen... In theory, this allocation should be done with SC's RTAlloc. The ptr to the function should be here passed as arg.
        #export the function to C when building a shared library
        proc UGenConstructor*(ins_SC : ptr ptr cfloat, bufsize_in : cint, samplerate_in : cdouble) : pointer {.exportc: "UGenConstructor"} =
            
            #Unpack args. These will overwrite the previous empty templates
            let 
                ins_Nim     {.inject.}  : CFloatPtrPtr = cast[CFloatPtrPtr](ins_SC)
                bufsize     {.inject.}  : int          = bufsize_in
                samplerate  {.inject.}  : float        = samplerate_in

            #Add the templates needed for UGenConstructor to unpack variable names declared with "var" (different from the one in UGenPerform, which uses unsafeAddr)
            `templates_for_constructor_var_declarations`

            #Add the templates needed for UGenConstructor to unpack variable names declared with "let"
            `templates_for_constructor_let_declarations`

            #Actual body of the constructor
            `code_block`

            #Constructor block: allocation of "ugen" variable and assignment of fields
            `constructor_body`

            #Return the "ugen" variable as void pointer
            return cast[pointer](ugen)

        #Destructor
        #[ proc UGenDestructor*(ugen : ptr UGen) : void {.exportc: "UGenDestructor".} =
            let ugen_void_cast = cast[pointer](ugen)
            if not ugen_void_cast.isNil():
                rt_free(ugen_void_cast)  ]#    
        
        defineDestructor(UGen, nil, nil, nil, `final_var_names`, true)
            

#This macro should in theory just work with the "new(a, b)" syntax, but for other syntaxes, the constructor macro correctly builds
#a correct call to "new(a, b)" instead of "new: \n a \n b" or "new a b" by extracting the nnkIdents from the other calls and 
#building a correct "new(a, b)" syntax out of them.
macro new*(var_names : varargs[typed]) =    
    var final_type = nnkTypeSection.newTree()
    var final_typedef = nnkTypeDef.newTree().add(nnkPragmaExpr.newTree(newIdentNode("UGen")).add(nnkPragma.newTree(newIdentNode("inject")))).add(newEmptyNode())
    var final_obj  = nnkObjectTy.newTree().add(newEmptyNode()).add(newEmptyNode())
    
    final_typedef.add(final_obj)
    final_type.add(final_typedef)
    
    var var_names_and_types = nnkRecList.newTree()

    for var_name in var_names:
        let var_type = var_name.getTypeImpl()

        var var_name_and_type = nnkIdentDefs.newTree()
        var_name_and_type.add(newIdentNode(var_name.strVal()))

        #object type
        if var_type.kind == nnkObjectTy:
            let fully_parametrized_object = var_name.getImpl()[2][0] #Extract the BracketExpr that represents the "MyObject[T, Y, ...]" syntax from the type.
            
            var_name_and_type.add(fully_parametrized_object)

        #ref object type. Don't support them as of now.
        #This should work just fine... Don't support it for now.
        elif var_type.kind == nnkRefTy:
            error("\"" & $var_name & "\"" & " is a ref object. ref objects are not supported.")
        
        #builtin type, expressed here as a nnkSym
        else:
            var_name_and_type.add(var_type)

        var_name_and_type.add(newEmptyNode())
        var_names_and_types.add(var_name_and_type)
    
    #Add samplerate_let variable
    var_names_and_types.add(
        nnkIdentDefs.newTree(
            newIdentNode("samplerate_let"),
            getType(float),
            newEmptyNode()
        )
    )

    #Add to final obj
    final_obj.add(var_names_and_types)

    return final_type

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
    
    #when supernova compilation, define a unlock_supernova_buffers() template that will contain all the unlock_buffer calls
    when defined(supernova):
        #template unlock_supernova_buffers() : untyped {.dirty.} =
        var 
            supernova_unlock_buffers_template_def = nnkTemplateDef.newTree(
                newIdentNode("unlock_supernova_buffers"),
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

            supernova_unlock_buffers_body = nnkStmtList.newTree()

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

                #when supernova compilation, add the unlock_buffer() calls to the unlock_supernova_buffers() template
                when defined(supernova):
                    var new_unlock_buffer = nnkCall.newTree(
                        newIdentNode("unlock_buffer"),
                        parsed_dot_syntax
                    )

                    supernova_unlock_buffers_body.add(new_unlock_buffer)

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
    
    #When supernova compilation, add the unlock template 
    when defined(supernova):
        supernova_unlock_buffers_template_def.add(supernova_unlock_buffers_body)
        result.add(supernova_unlock_buffers_template_def)

#Unpack the fields of the ugen. Objects will be passed as unsafeAddr, to get their direct pointers. What about other inbuilt types other than floats, however??n
macro unpackUGenVariables*(t : typed) =
    return unpackUGenVariablesProc(t)

#Simply cast the inputs from SC in a indexable form in Nim
macro castInsOuts*() =
    return quote do:
        let 
            ins_Nim  {.inject.}  : CFloatPtrPtr = cast[CFloatPtrPtr](ins_SC)
            outs_Nim {.inject.}  : CFloatPtrPtr = cast[CFloatPtrPtr](outs_SC)

#Need to use a template with {.dirty.} pragma to not hygienize the symbols to be like "ugen1123123", but just as written, "ugen".
template perform*(code_block : untyped) {.dirty.} =
    #export the function to C when building a shared library
    proc UGenPerform*(ugen_void : pointer, bufsize : cint, ins_SC : ptr ptr cfloat, outs_SC : ptr ptr cfloat) : void {.exportc: "UGenPerform".} =    
        
        #Add the templates needed for UGenPerform to unpack variable names declared with "var" in cosntructor
        generateTemplatesForPerformVarDeclarations()

        #Cast the void* to UGen*
        let ugen = cast[ptr UGen](ugen_void)

        #cast ins and outs
        castInsOuts()

        #Unpack the variables at compile time. It will also expand on any Buffer types.
        unpackUGenVariables(UGen)

        #Append the whole code block
        code_block

        #UNLOCK buffers when supernova is used...
        when defined(supernova):
            unlock_supernova_buffers()

    #Write IO infos to txt file... This should be fine here in perform, as any nimcollider file must provide a perform block to be compiled.
    when defined(supernim):
        import os
        
        #static == compile time block
        static:
            let text = $ugen_inputs & "\n" & $ugen_input_names & "\n" & $ugen_outputs
            let fullPathToNewFolder = getTempDir() #this has been passed in as command argument with -d:tempDir=fullPathToNewFolder
            writeFile($fullPathToNewFolder & "IO.txt", text)

#Simply wrap the code block in a for loop. Still marked as {.dirty.} to export symbols to context.
template sample*(code_block : untyped) {.dirty.} =
    
    #Right before sample, define the new in1, in2, etc... macro for single sample retireval
    generate_inputs_templates(ugen_inputs, 1)

    #Right before sample, define the new out1, out2, etc... macro for single sample retireval
    generate_outputs_templates(ugen_outputs, 1)

    for audio_index_loop in 0..(bufsize - 1):
        code_block
    
    #This is in case the user accesses in1, in2, etc again after sample block. 
    #Since the template has been changed, now it would still read kr in the perform block.
    let audio_index_loop = 0