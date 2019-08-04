#Here I should just import all the macros functions that I am using, to not compile the entire macros module.
import macros

const
    max_inputs_outputs  = 32

#Generate in1, in2, in3...etc templates
macro generate_inputs_templates(num_of_inputs : typed) : untyped =
    var final_statement = nnkStmtList.newTree()

    #Tree retrieved thanks to:
    #[
        dumpAstGen:
            template in1*() : untyped =
                ins[0][audio_index_loop] 

            template in1_kr*() : untyped =
                ins[0][0] 
    ]#

    let 
        num_of_inputs_VAL = num_of_inputs.intVal()

    for i in 1..num_of_inputs_VAL:
        var temp_in_stmt_list = nnkStmtList.newTree(
            #template for AR input, named in1, in2, etc...
            nnkTemplateDef.newTree(
                nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("in" & $i),             #name of template
                ),
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
                    newIdentNode("ins"),             #name of the ins buffer
                    newLit(int(i - 1))               #literal value
                    ),
                    newIdentNode("audio_index_loop") #name of the looping variable
                )
                )
            ),

            #template for KR input, named in1_kr, in2_kr, etc...
            nnkTemplateDef.newTree(
                nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("in" & $i & "_kr"),      #name of template 
                ),
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
                    newIdentNode("ins"),             #name of the ins buffer
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

#Generate out1, out2, out3...etc templates
macro generate_outputs_templates(num_of_outputs : typed) : untyped =
    var final_statement = nnkStmtList.newTree()

    #Tree retrieved thanks to:
    #[
        dumpAstGen:
            template out1*() : untyped =
                outs[0][audio_index_loop] 

            template out1_kr*() : untyped =
                outs[0][0] 
    ]#

    let 
        num_of_outputs_VAL = num_of_outputs.intVal()

    for i in 1..num_of_outputs_VAL:
        var temp_out_stmt_list = nnkStmtList.newTree(
            #template for AR input, named out1, out2, etc...
            nnkTemplateDef.newTree(
                nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("out" & $i), #name of template
                ),
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
                    newIdentNode("outs"),             #name of the ins buffer
                    newLit(int(i - 1))                #literal value
                    ),
                    newIdentNode("audio_index_loop")  #name of the looping variable
                )
                )
            ),

            #template for KR input, named out1_kr, out2_kr, etc...
            nnkTemplateDef.newTree(
                nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("out" & $i & "_kr"),      #name of template
                ),
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
                    newIdentNode("outs"),             #name of the ins buffer
                    newLit(int(i - 1))                #literal value
                    ),
                    newLit(0)                         # outs[...][0]
                )
                )
            )
        )

        #Accumulate result
        final_statement.add(temp_out_stmt_list)

    return final_statement

#The block form (derived from using num_of_inputs as int literal, and param_names as a code block.):
#inputs 1:
#   "freq"
macro inputs*(num_of_inputs : untyped, param_names : untyped) : untyped =
    
    var 
        num_of_inputs_VAL : int
        param_names_array_node : NimNode = nnkBracket.newTree()

    #Must be an int literal
    if num_of_inputs.kind != nnkIntLit: #Just as the expectKind proc
        error("Expected the number of inputs to be expressed by an integer literal value")

    if param_names.kind != nnkStmtList:
        error("Expected a block statement after the number of inputs")
    
    num_of_inputs_VAL = int(num_of_inputs.intVal)     #Actual value of the int literal

    if num_of_inputs_VAL < 0:
        error("Expected a positive number for inputs number")
    
    if num_of_inputs_VAL > max_inputs_outputs:
        error("Exceeded maximum number of inputs, " & $max_inputs_outputs)

    var 
        statement_counter = 0

    for statement in param_names.children():
        if statement.kind != nnkStrLit:
            error("Expected parameter name number " & $(statement_counter + 1) & " to be a string literal value")
        
        param_names_array_node.add newLit(statement.strVal())
        statement_counter += 1
    
    if statement_counter != num_of_inputs_VAL:
        error("Expected " & $num_of_inputs_VAL & " param names, got " & $statement_counter)

    return quote do: 
        const 
            ugen_inputs {.inject.} = `num_of_inputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to insert variable from macro's scope
            ugen_input_names {.inject.} = `param_names_array_node`  #It's possible to insert NimNodes directly in the code block 
        generate_inputs_templates(`num_of_inputs_VAL`)

macro inputs*(num_of_inputs : untyped, param_names : varargs[untyped]) : untyped = 
    
    var 
        num_of_inputs_VAL : int
        param_names_array_node : NimNode = nnkBracket.newTree()

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
                
                param_names_array_node.add newLit(statement.strVal())
                param_names_counter += 1

            statement_counter += 1

        if param_names_counter > 0:
            if param_names_counter != num_of_inputs_VAL:
                error("Expected " & $num_of_inputs_VAL & " param names, got " & $param_names_counter)

            return quote do: 
                const 
                    ugen_inputs {.inject.} = `num_of_inputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to insert variable from macro's scope
                    ugen_input_names {.inject.} = `param_names_array_node`  #It's possible to insert NimNodes directly in the code block
                generate_inputs_templates(`num_of_inputs_VAL`)
        else:
            return quote do:
                const 
                    ugen_inputs {.inject.} = `num_of_inputs_VAL`  
                    ugen_input_names {.inject.} = ["NO_PARAM_NAMES"]
                generate_inputs_templates(`num_of_inputs_VAL`)

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
        
        #Empty bracket statement: []
        param_names_array_node = nnkBracket.newTree()
        
        #Check for correct length of param names
        if len(param_names) > 0:
            if len(param_names) != num_of_inputs_VAL:
                error("Expected " & $num_of_inputs_VAL & " param names, got " & $(len(param_names)))
            
            #Check if all param names are string literal values
            for index, param_name in param_names:
                if param_name.kind != nnkStrLit:
                    error("Expected parameter name number " & $(index + 1) & " to be a string literal value")
                
                #Add literal string value to the nnkBracket NimNode
                param_names_array_node.add newLit(param_name.strVal())
            
            #[ 
                param_names_array_node will now be in the form:
                nnkBracket.newTree(
                    newLit("freq"),
                    newLit("phase")
                ) 
                Which is a bracket statement, like: ["freq", "phase"]
            ]#
            
            #Actual return statement: a valid NimNode wrapped in the "quote do:" syntax.
            return quote do: 
                const 
                    ugen_inputs {.inject.} = `num_of_inputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to insert variable from macro's scope
                    ugen_input_names {.inject.} = `param_names_array_node`  #It's possible to insert NimNodes directly in the code block
                generate_inputs_templates(`num_of_inputs_VAL`)
        else:
            return quote do:
                const 
                    ugen_inputs {.inject.} = `num_of_inputs_VAL` 
                    ugen_input_names {.inject.} = ["NO_PARAM_NAMES"]  
                generate_inputs_templates(`num_of_inputs_VAL`)
        
#The block form (derived from using num_of_outputs as int literal, and param_names as a code block.):
#outputs 1:
#   "freq"
macro outputs*(num_of_outputs : untyped, param_names : untyped) : untyped =
    
    var 
        num_of_outputs_VAL : int
        param_names_array_node : NimNode = nnkBracket.newTree()

    #Must be an int literal
    if num_of_outputs.kind != nnkIntLit: #Just as the expectKind proc
        error("Expected the number of outputs to be expressed by an integer literal value")

    if param_names.kind != nnkStmtList:
        error("Expected a block statement after the number of outputs")
    
    num_of_outputs_VAL = int(num_of_outputs.intVal)     #Actual value of the int literal

    if num_of_outputs_VAL < 0:
        error("Expected a positive number for outputs number")

    if num_of_outputs_VAL > max_inputs_outputs:
        error("Exceeded maximum number of outputs, " & $max_inputs_outputs)

    var 
        statement_counter = 0

    for statement in param_names.children():
        if statement.kind != nnkStrLit:
            error("Expected parameter name number " & $(statement_counter + 1) & " to be a string literal value")
        
        param_names_array_node.add newLit(statement.strVal())
        statement_counter += 1
    
    if statement_counter != num_of_outputs_VAL:
        error("Expected " & $num_of_outputs_VAL & " param names, got " & $statement_counter)

    return quote do: 
        const 
            ugen_outputs {.inject.} = `num_of_outputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to insert variable from macro's scope
            ugen_output_names {.inject.} = `param_names_array_node`  #It's possible to insert NimNodes directly in the code block 
        generate_outputs_templates(`num_of_outputs_VAL`)

macro outputs*(num_of_outputs : untyped, param_names : varargs[untyped]) : untyped = 
    
    var 
        num_of_outputs_VAL : int
        param_names_array_node : NimNode = nnkBracket.newTree()

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
                
                param_names_array_node.add newLit(statement.strVal())
                param_names_counter += 1

            statement_counter += 1

        if param_names_counter > 0:
            if param_names_counter != num_of_outputs_VAL:
                error("Expected " & $num_of_outputs_VAL & " param names, got " & $param_names_counter)

            return quote do: 
                const 
                    ugen_outputs {.inject.} = `num_of_outputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to insert variable from macro's scope
                    ugen_output_names {.inject.} = `param_names_array_node`  #It's possible to insert NimNodes directly in the code block
                generate_outputs_templates(`num_of_outputs_VAL`)
        else:
            return quote do:
                const 
                    ugen_outputs {.inject.} = `num_of_outputs_VAL`  
                    ugen_output_names {.inject.} = ["NO_PARAM_NAMES"]
                generate_outputs_templates(`num_of_outputs_VAL`)

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
        
        #Empty bracket statement: []
        param_names_array_node = nnkBracket.newTree()
        
        #Check for correct length of param names
        if len(param_names) > 0:
            if len(param_names) != num_of_outputs_VAL:
                error("Expected " & $num_of_outputs_VAL & " param names, got " & $(len(param_names)))
            
            #Check if all param names are string literal values
            for index, param_name in param_names:
                if param_name.kind != nnkStrLit:
                    error("Expected parameter name number " & $(index + 1) & " to be a string literal value")
                
                #Add literal string value to the nnkBracket NimNode
                param_names_array_node.add newLit(param_name.strVal())
            
            #[ 
                param_names_array_node will now be in the form:
                nnkBracket.newTree(
                    newLit("freq"),
                    newLit("phase")
                ) 
                Which is a bracket statement, like: ["freq", "phase"]
            ]#
            
            #Actual return statement: a valid NimNode wrapped in the "quote do:" syntax.
            return quote do: 
                const
                    ugen_outputs {.inject.} = `num_of_outputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to insert variable from macro's scope
                    ugen_output_names {.inject.} = `param_names_array_node`  #It's possible to insert NimNodes directly in the code block
                generate_outputs_templates(`num_of_outputs_VAL`)
        else:
            return quote do:
                const 
                    ugen_outputs {.inject.} = `num_of_outputs_VAL` 
                    ugen_output_names {.inject.} = ["NO_PARAM_NAMES"]  
                generate_outputs_templates(`num_of_outputs_VAL`)

macro constructor*(code_block : untyped) =

    #new: ... syntax could be built by parsing directly this block of code,
    #and construct the types by looking at IntLits, StrLits, and ObjConstr (for custom objects)
    #echo treeRepr code_block

    #ALSO, I could have my own parser that looks for assignment NimNodes, and add the var names to a seq[NimNode] (with nnkIdents).
    #On first occurance of a name, add a "var" prefix. (Or a "let", without allowing the changing of the values.)
    #In the case of using the same method in the "perform" macro, always prepend the "var".
    #HOWEVER, this would slow parsing and compilation times. Is it worth it?

    var 
        empty_var_statements : seq[NimNode]
        call_to_new_macro : NimNode

    #Look if "new" macro call is the last statement in the block.
    if code_block.last().kind != nnkCall and code_block.last().kind != nnkCommand:
        error("Last constructor statement must be a call to \"new\".")
    elif code_block.last()[0].strVal() != "new":
        error("Last constructor statement must be a call to \"new\".")
    else:
        call_to_new_macro = code_block.last()

    #[
        REDUCE ALL THESE FOR LOOPS IN A BETTER WAY!!
    ]#

    #Look for empty var statements
    for statement in code_block:
        if statement.kind == nnkVarSection:
            for var_declaration in statement:
                #Found one! add the sym to seq. It's a nnkIdent.
                if var_declaration[2].kind == nnkEmpty:
                    empty_var_statements.add(var_declaration[0])
    
    #Find the "new" call, and check if any empty_var_statements is passed through the call
    for new_macro_var_name in call_to_new_macro:
        for empty_var_statement in empty_var_statements:
            if empty_var_statement == new_macro_var_name: #They both are nnkIdents. They can be compared.
                error("\"" & $(empty_var_statement.strVal()) & "\" is a non-initialized variable. It can't be an input to a \"new\" statement.")

    return quote do:
        `code_block`

#[
    new(a, b, c)
]#
macro new*(var_names : varargs[typed]) =    
    result = nnkStmtList.newTree()
    
    for var_name in var_names:
        let var_type = var_name.getTypeImpl()

        #object type
        if var_type.kind == nnkObjectTy:
            let fully_parametrized_object = var_name.getImpl()[2][0] #Extract the BracketExpr that represents the "MyObject[T, Y, ...]" syntax from the type.
            
            #object is not built from generics
            if fully_parametrized_object.kind == nnkSym:
                echo $var_name & " : " & $(fully_parametrized_object.strVal())
            
            #object is built from generics form
            else:
                var full_type_string = $(fully_parametrized_object[0].strVal()) & "["   #First entry is the type name as symbol. All remaining children are the parametrized generic types.
                
                #skip first step, already extracted
                for i in 1..fully_parametrized_object.len() - 1:
                    let parametrized_type = fully_parametrized_object[i].strVal()
                    full_type_string.add(parametrized_type)
                    if i != fully_parametrized_object.len() - 1:
                        full_type_string.add(", ")
                
                full_type_string.add("]")
                
                echo $var_name & " : " & $full_type_string

        #ref object type. Don't support them as of now.
        elif var_type.kind == nnkRefTy:
            error("\"" & $var_name & "\"" & " is a ref object. ref objects are not supported.")
            #This should work just fine... Don't support it for now.
            #echo treeRepr var_name.getImpl()
        
        #builtin type, expressed here as a nnkSym
        else:
            echo $var_name & " : " & $(var_type.strVal())