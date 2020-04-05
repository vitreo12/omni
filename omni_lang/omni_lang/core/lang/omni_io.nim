import macros

const max_inputs_outputs = 32

const acceptedCharsForParamName = {'a'..'z', 'A'..'Z', '0'..'9', '_'}

proc generate_min_max_procs(index : SomeInteger) : NimNode {.compileTime.} =
    let 
        in_num = "in" & $index
        in_min = in_num & "_min"
        in_max = in_num & "_max"

    return nnkProcDef.newTree(
        nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode(in_num & "_min_max")         
        ),
        newEmptyNode(),
        nnkGenericParams.newTree(
        nnkIdentDefs.newTree(
            newIdentNode("T"),
            newIdentNode("SomeFloat"),
            newEmptyNode()
        )
        ),
        nnkFormalParams.newTree(
        newIdentNode("T"),
        nnkIdentDefs.newTree(
            newIdentNode(in_num),
            newIdentNode("T"),
            newEmptyNode()
        )
        ),
        newEmptyNode(),
        newEmptyNode(),
        nnkStmtList.newTree(
        nnkIfStmt.newTree(
            nnkElifBranch.newTree(
            nnkInfix.newTree(
                newIdentNode("<"),
                newIdentNode(in_num),
                newIdentNode(in_min)
            ),
            nnkStmtList.newTree(
                nnkReturnStmt.newTree(
                nnkCall.newTree(
                    newIdentNode("T"),
                    newIdentNode(in_min)
                )
                )
            )
            ),
            nnkElifBranch.newTree(
            nnkInfix.newTree(
                newIdentNode(">"),
                newIdentNode(in_num),
                newIdentNode(in_max)
            ),
            nnkStmtList.newTree(
                nnkReturnStmt.newTree(
                nnkCall.newTree(
                    newIdentNode("T"),
                    newIdentNode(in_max)
                )
                )
            )
            ),
            nnkElse.newTree(
            nnkStmtList.newTree(
                nnkReturnStmt.newTree(
                newIdentNode(in_num)
                )
            )
            )
        )
        )
    )

proc generate_ar_in_template(index : SomeInteger, has_min_max : SomeInteger) : NimNode {.compileTime.} =
    let in_num = "in" & $index

    if has_min_max == 1:
        return nnkTemplateDef.newTree(
            newIdentNode(in_num),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("untyped")
            ),
            newEmptyNode(),
            newEmptyNode(),
            nnkStmtList.newTree(
                nnkCall.newTree(
                    newIdentNode(in_num & "_min_max"),
                    nnkBracketExpr.newTree(
                        nnkBracketExpr.newTree(
                            newIdentNode("ins_Nim"),
                            newLit(int(index - 1))
                        ),
                        newIdentNode("audio_index_loop")
                    )
                )
            )
        )
    else:
        return nnkTemplateDef.newTree(
            newIdentNode(in_num),             #name of template
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
                        newLit(int(index - 1))               #literal value
                    ),
                    newIdentNode("audio_index_loop") #name of the looping variable
                )
            )
        )

proc generate_kr_in_template(index : SomeInteger, has_min_max : SomeInteger) : NimNode {.compileTime.} =
    let in_num = "in" & $index
    if has_min_max == 1:
        return nnkTemplateDef.newTree(
            newIdentNode(in_num),             #name of template
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("untyped")
            ),
            newEmptyNode(),
            newEmptyNode(),
            nnkStmtList.newTree(
                nnkCall.newTree(
                    newIdentNode(in_num & "_min_max"),
                    nnkBracketExpr.newTree(
                        newIdentNode("ins_Nim"),             #name of the ins buffer
                        newLit(int(index - 1))               #literal value
                    ),
                    newLit(0)                        # ins[...][0]
                )
            )
        )
    else:
        return nnkTemplateDef.newTree(
            newIdentNode(in_num),             #name of template
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
                        newLit(int(index - 1))               #literal value
                    ),
                    newLit(0)                        # ins[...][0]
                )
            )
        )

#Generate in1, in2, in3...etc templates
macro generate_inputs_templates*(num_of_inputs : typed, generate_ar : typed, generate_min_max : typed = 0, has_min_max : typed = 0) : untyped =
    var final_statement = nnkStmtList.newTree()

    var 
        num_of_inputs_VAL = num_of_inputs.intVal()
        generate_ar = generate_ar.intVal() #boolVal() doesn't work here.
        generate_min_max = generate_min_max.intVal()
        has_min_max = has_min_max.intVal()

    if generate_min_max == 1:
        for i in 1..num_of_inputs_VAL:
            final_statement.add(generate_min_max_procs(i))

    if generate_ar == 1:
        for i in 1..num_of_inputs_VAL:
            final_statement.add(generate_ar_in_template(i, has_min_max))

    else:
        for i in 1..num_of_inputs_VAL:
            final_statement.add(generate_kr_in_template(i, has_min_max))

    return final_statement

macro generate_args_templates*(num_of_inputs : typed) : untyped =
    var 
        final_statement = nnkStmtList.newTree()
        num_of_inputs_VAL = num_of_inputs.intVal()

    for i in 1..num_of_inputs_VAL:
        let temp_in_stmt_list = nnkStmtList.newTree(
            nnkTemplateDef.newTree(
                newIdentNode("arg" & $i),
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
                    newIdentNode("in" & $i)
                )
            )
        )

        #Accumulate result
        final_statement.add(temp_in_stmt_list)

    return final_statement


macro generate_outputs_templates*(num_of_outputs : typed) : untyped =
    var 
        final_statement = nnkStmtList.newTree()
        num_of_outputs_VAL = num_of_outputs.intVal()

    for i in 1..num_of_outputs_VAL:
        #template for AR output, named out1, out2, etc...
        let temp_in_stmt_list = nnkTemplateDef.newTree(
            newIdentNode("out" & $i),
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

    return final_statement

proc checkValidParamName(param_name : string) : void =
    for individualChar in param_name:
        if not (individualChar in acceptedCharsForParamName):
            error("Invalid character " & $individualChar & $ " in input name " & $param_name)

proc extractDefaultMinMax(default_min_max : NimNode, param_name : string) : tuple[defult : float, min : float, max : float] {.compileTime.} =
    let default_min_max_len = default_min_max.len()

    var 
        default_num : float = 0.0
        min_num     : float = 0.0
        max_num     : float = 0.0

    #Extract def / min / max values
    for index, value in default_min_max.pairs():
        let value_kind = value.kind
        
        #{0, 0, 1} / {0, 1}
        if value_kind == nnkIntLit or value_kind == nnkFloatLit:
            var value_num : float
            if value_kind == nnkIntLit:
                value_num = float(value.intVal()) 
            else:
                value_num = value.floatVal()

            if default_min_max_len == 3:
                case index:
                    of 0:
                        default_num = value_num
                    of 1:
                        min_num = value_num
                    of 2:
                        max_num = value_num
                    else:
                        discard
            elif default_min_max_len == 2:
                case index:
                    of 0:
                        min_num = value_num
                    of 1:
                        max_num = value_num
                    else:
                        discard

        #{0 0 1} / {0 1}
        elif value_kind == nnkCommand:
            assert value.len == 2
            
            let second_stmt = value[1]
            let second_stmt_kind = second_stmt.kind

            var
                default_stmt : NimNode
                default_stmt_kind : NimNodeKind
                min_stmt : NimNode
                min_stmt_kind : NimNodeKind
                max_stmt : NimNode
                max_stmt_kind : NimNodeKind

            #{0 0 1}
            if second_stmt_kind == nnkCommand:
                default_stmt = value[0]
                default_stmt_kind = default_stmt.kind
                min_stmt = second_stmt[0]
                min_stmt_kind = min_stmt.kind
                max_stmt = second_stmt[1]
                max_stmt_kind = max_stmt.kind

            #{0 1}
            elif second_stmt_kind == nnkIntLit or second_stmt_kind == nnkFloatLit:
                min_stmt = value[0]
                min_stmt_kind = min_stmt.kind
                max_stmt = value[1]
                max_stmt_kind = max_stmt.kind

            else:
                error("Invalid syntax for input \"" & $param_name & "\"")

            #Might be empty
            if not isNil(default_stmt):
                if default_stmt_kind == nnkIntLit:
                    default_num = float(default_stmt.intVal())
                elif default_stmt_kind == nnkFloatLit:
                    default_num = default_stmt.floatVal()
                else:
                    error("Invalid syntax for default value of input \"" & $param_name & "\"")

            if min_stmt_kind == nnkIntLit:
                min_num = float(min_stmt.intVal())
            elif min_stmt_kind == nnkFloatLit:
                min_num = min_stmt.floatVal()
            else:
                error("Invalid syntax for min value of input \"" & $param_name & "\"")

            if max_stmt_kind == nnkIntLit:
                max_num = float(max_stmt.intVal())
            elif max_stmt_kind == nnkFloatLit:
                max_num = max_stmt.floatVal()
            else:
                error("Invalid syntax for max value of input \"" & $param_name & "\"")
            
        else:
            error("Invalid syntax for input \"" & $param_name & "\"")

    return (default_num, min_num, max_num)

proc buildDefaultMinMaxArrays(num_of_inputs : int, default_vals : seq[float], min_vals : seq[float], max_vals : seq[float]) : NimNode {.compileTime.} =
    let default_vals_len = default_vals.len()

    #Find mismatch. Perhaps user hasn't defined def/min/max for some params
    if num_of_inputs != default_vals_len:
        error("Got " & $num_of_inputs & " number of inputs but only " & $default_vals_len & " default / min / max values.")

    result = nnkConstSection.newTree()

    var 
        defaults_array = nnkConstDef.newTree(
            nnkPragmaExpr.newTree(
                newIdentNode("default_vals"),
                nnkPragma.newTree(
                    newIdentNode("inject")
                )
            ),
            newEmptyNode()
        )

        defaults_array_bracket = nnkBracket.newTree()

    for i in 0..(num_of_inputs-1):
        let
            i_plus_one = i + 1
            default_val = default_vals[i]
            min_val = min_vals[i]
            max_val = max_vals[i]

        defaults_array_bracket.add(newLit(default_val))

        result.add(
            nnkConstDef.newTree(
                newIdentNode("in" & $(i_plus_one) & "_min"),
                newEmptyNode(),
                newLit(min_val)
            ),
            nnkConstDef.newTree(
                newIdentNode("in" & $(i_plus_one) & "_max"),
                newEmptyNode(),
                newLit(max_val)
            )
        )
    
    defaults_array.add(defaults_array_bracket)

    result.add(defaults_array)
    

macro ins*(num_of_inputs : typed, param_names : untyped = nil) : untyped =
    
    var 
        num_of_inputs_VAL : int
        param_names_string : string = ""
        param_names_node : NimNode

        default_vals : seq[float]
        min_vals     : seq[float]
        max_vals     : seq[float]

    let param_names_kind = param_names.kind

    #Must be an int literal OR nnkStmtListExpr (for ins: 1)
    if num_of_inputs.kind == nnkIntLit: 
        num_of_inputs_VAL = int(num_of_inputs.intVal)     
    elif num_of_inputs.kind == nnkStmtListExpr:
        num_of_inputs_VAL = int(num_of_inputs[0].intVal)    
    else:
        error("Expected the number of inputs to be expressed as an integer literal value")

    if param_names_kind != nnkStmtList and param_names_kind != nnkStrLit and param_names_kind != nnkCommand and param_names_kind != nnkNilLit:
        error("Expected a block statement after the number of inputs")


    #Always have at least one input
    if num_of_inputs_VAL == 0:
        num_of_inputs_VAL = 1
    elif num_of_inputs_VAL < 0:
        error("Expected a positive number for inputs number")
    elif num_of_inputs_VAL > max_inputs_outputs:
        error("Exceeded maximum number of inputs, " & $max_inputs_outputs)

    var statement_counter = 0

    #This is for the inputs 1, "freq" case. (where "freq" is not viewed as varargs)
    #input 2, "freq", "stmt" is covered in the other macro
    if param_names_kind == nnkStrLit:
        let param_name = param_names.strVal()
        
        checkValidParamName(param_name)
        
        param_names_string.add($param_name & ",")
        statement_counter = 1

    #block case
    else:
        #multiple statements: "freq" {440, 0, 22000} OR "freq" {440 0 22000}
        if param_names_kind == nnkStmtList:
            for statement in param_names.children():
                let statement_kind = statement.kind

                #"freq"
                if statement_kind == nnkStrLit:
                    let param_name = statement.strVal()

                    checkValidParamName(param_name)
                    
                    param_names_string.add($param_name & ",")
                
                #"freq" {440, 0, 22000} OR "freq" {440 0 22000}
                elif statement_kind == nnkCommand:
                    assert statement.len == 2

                    #The name of the param
                    let param_name_node = statement[0]
                    if param_name_node.kind != nnkStrLit:
                        error("Expected input name number " & $(statement_counter + 1) & " to be a string literal value")

                    let param_name = param_name_node.strVal()
                    checkValidParamName(param_name)

                    param_names_string.add($param_name & ",")
                
                    #The list of { }
                    let default_min_max = statement[1]

                    if default_min_max.kind != nnkCurly:
                        error("Expected default / min / max values for \"" & $param_name & "\" to be wrapped in curly brackets.")

                    let (default_val, min_val, max_val) = extractDefaultMinMax(default_min_max, param_name)
                    
                    default_vals.add(default_val)
                    min_vals.add(min_val)
                    max_vals.add(max_val)
                
                #Just {0, 0, 1} / {0 0 1}, no param name provided!
                elif statement_kind == nnkCurly:
                    let param_name = "in" & $(statement_counter+1)
                    
                    param_names_string.add($param_name & ",")

                    let (default_val, min_val, max_val) = extractDefaultMinMax(statement, param_name)
                    
                    default_vals.add(default_val)
                    min_vals.add(min_val)
                    max_vals.add(max_val)

                statement_counter += 1
                    
        #Single "freq" {440, 0, 22000} OR "freq" on same line: ins 1, "freq" {440, 0, 22000}
        elif param_names_kind == nnkCommand:
            error("ins: syntax not implemented yet")

    #Remove trailing coma
    if param_names_string.len > 1:
        param_names_string = param_names_string[0..param_names_string.high-1]
    
    #inputs count mismatch
    if param_names_kind == nnkNilLit:
        param_names_string = "__NO_PARAM_NAMES__"
    else:
        if statement_counter != num_of_inputs_VAL:
            error("Expected " & $num_of_inputs_VAL & " input names, got " & $statement_counter)

    #Assign to node
    param_names_node = newLit(param_names_string)

    #If default/min/max are defined
    if default_vals.len > 0:
        let defaults_mins_maxs = buildDefaultMinMaxArrays(num_of_inputs_VAL, default_vals, min_vals, max_vals)

        return quote do: 
            const 
                omni_inputs {.inject.}      = `num_of_inputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to insert variable from macro's scope
                omni_input_names {.inject.} = `param_names_node`  #It's possible to insert NimNodes directly in the code block 

            #const statement for defaults / mins / maxs
            `defaults_mins_maxs`
            
            #Generate procs for min/max
            generate_inputs_templates(`num_of_inputs_VAL`, 0, 1)

            generate_args_templates(`num_of_inputs_VAL`)
            
            #Export to C
            proc Omni_UGenInputs() : int32 {.exportc: "Omni_UGenInputs", dynlib.} =
                return int32(omni_inputs)

            proc Omni_UGenInputNames() : ptr cchar {.exportc: "Omni_UGenInputNames", dynlib.} =
                return cast[ptr cchar](omni_input_names)
    
    #no default/min/max
    else:
        return quote do: 
            const 
                omni_inputs {.inject.}      = `num_of_inputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to insert variable from macro's scope
                omni_input_names {.inject.} = `param_names_node`  #It's possible to insert NimNodes directly in the code block 
            
            generate_inputs_templates(`num_of_inputs_VAL`, 0)

            generate_args_templates(`num_of_inputs_VAL`)
            
            #Export to C
            proc Omni_UGenInputs() : int32 {.exportc: "Omni_UGenInputs", dynlib.} =
                return int32(omni_inputs)

            proc Omni_UGenInputNames() : ptr cchar {.exportc: "Omni_UGenInputNames", dynlib.} =
                return cast[ptr cchar](omni_input_names)


macro outs*(num_of_outputs : typed, param_names : untyped = nil) : untyped =
    
    var 
        num_of_outputs_VAL : int
        param_names_string : string = ""
        param_names_node : NimNode

    let param_names_kind = param_names.kind

    #Must be an int literal OR nnkStmtListExpr (for ins: 1)
    if num_of_outputs.kind == nnkIntLit: 
        num_of_outputs_VAL = int(num_of_outputs.intVal)     
    elif num_of_outputs.kind == nnkStmtListExpr:
        num_of_outputs_VAL = int(num_of_outputs[0].intVal)    
    else:
        error("Expected the number of outputs to be expressed as an integer literal value")

    if param_names_kind != nnkStmtList and param_names_kind != nnkStrLit and param_names_kind != nnkCommand and param_names_kind != nnkNilLit:
        error("Expected a block statement after the number of outputs")

    #Always have at least one output
    if num_of_outputs_VAL == 0:
        num_of_outputs_VAL = 1
    elif num_of_outputs_VAL < 0:
        error("Expected a positive number for outputs number")
    elif num_of_outputs_VAL > max_inputs_outputs:
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
                error("Expected output name number " & $(statement_counter + 1) & " to be a string literal value")
            
            let param_name = statement.strVal()

            checkValidParamName(param_name)
            
            param_names_string.add($param_name & ",")
            statement_counter += 1

    #Remove trailing coma
    if param_names_string.len > 1:
        param_names_string = param_names_string[0..param_names_string.high-1]
    
    #outputs count mismatch
    if param_names_kind == nnkNilLit:
        param_names_string = "__NO_PARAM_NAMES__"
    else:
        if statement_counter != num_of_outputs_VAL:
            error("Expected " & $num_of_outputs_VAL & " input names, got " & $statement_counter)
    
    #Assign to node
    param_names_node = newLit(param_names_string)

    return quote do: 
        const 
            omni_outputs {.inject.}      = `num_of_outputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to outsert variable from macro's scope
            omni_output_names {.inject.} = `param_names_node`  #It's possible to outsert NimNodes directly in the code block 
        
        #generate_outputs_templates(`num_of_outputs_VAL`)
        
        #Export to C
        proc Omni_UGenOutputs() : int32 {.exportc: "Omni_UGenOutputs", dynlib.} =
            return int32(omni_outputs)

        proc Omni_UGenOutputNames() : ptr cchar {.exportc: "Omni_UGenOutputNames", dynlib.} =
            return cast[ptr cchar](omni_output_names)
