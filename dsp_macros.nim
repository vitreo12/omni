#Here I should just import all the macros functions that I am using, to not compile the entire macros module.
import macros

const max_inputs_outputs  = 32

#Generate in1, in2, in3...etc templates
macro generate_inputs_templates(num_of_inputs : typed) : untyped =
    var final_statement = nnkStmtList.newTree()

    #Tree retrieved thanks to:
    #[
        dumpAstGen:
            template in1*() : untyped =
                ins_Nim[0][audio_index_loop] 

            template in1_kr*() : untyped =
                ins_Nim[0][0] 
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
                    newIdentNode("ins_Nim"),             #name of the ins buffer
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

#Generate out1, out2, out3...etc templates
macro generate_outputs_templates(num_of_outputs : typed) : untyped =
    var final_statement = nnkStmtList.newTree()

    #Tree retrieved thanks to:
    #[
        dumpAstGen:
            template out1*() : untyped =
                outs_Nim[0][audio_index_loop] 

            template out1_kr*() : untyped =
                outs_Nim[0][0] 
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
                    newIdentNode("outs_Nim"),             #name of the ins buffer
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
                    newIdentNode("outs_Nim"),             #name of the ins buffer
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
macro ins*(num_of_inputs : untyped, param_names : untyped) : untyped =
    
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

macro ins*(num_of_inputs : untyped, param_names : varargs[untyped]) : untyped = 
    
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
macro outs*(num_of_outputs : untyped, param_names : untyped) : untyped =
    
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

macro outs*(num_of_outputs : untyped, param_names : varargs[untyped]) : untyped = 
    
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


macro struct*(struct_name : untyped, code_block : untyped) : untyped =
    var 
        final_stmt_list = nnkStmtList.newTree()
        type_section  = nnkTypeSection.newTree()
        obj_type_def  = nnkTypeDef.newTree()      #the Phasor_obj block
        obj_ty        = nnkObjectTy.newTree()     #the body of the Phasor_obj   
        rec_list      = nnkRecList.newTree()      #the variable declaration section of Phasor_obj
        
        ptr_type_def  = nnkTypeDef.newTree()      #the Phasor = ptr Phasor_obj block
        ptr_ty        = nnkPtrTy.newTree()        #the ptr type expressing ptr Phasor_obj
        
        init_fun      = nnkProcDef.newTree()      #the init* function
        formal_params = nnkFormalParams.newTree()
        fun_body      = nnkStmtList.newTree()

    obj_ty.add(newEmptyNode())
    obj_ty.add(newEmptyNode())
    
    var 
        obj_name : NimNode
        ptr_name : NimNode
        generics = nnkGenericParams.newTree()  #If generics are present in struct definition
        generics_names : seq[NimNode]

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
        #Note that init_fun for generics has just one newEmptyNode()
        init_fun.add(nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("init")
            ),
            newEmptyNode()
        )

        for index, child in struct_name:
            if index == 0:
                continue
            else:
                var generic_proc = nnkIdentDefs.newTree()
                    
                #If singular [T]
                if child.len == 0:
                    generics_names.add(child)
                    generic_proc.add(child)
                    generic_proc.add(newEmptyNode())
                    generic_proc.add(newEmptyNode())
                    generics.add(generic_proc)

                #If [T : SomeFloat or SomeInteger... etc...]
                else:
                    #All the generics (including the "or" infixes, etc...)
                    for inner_index, inner_child in child:

                        #Add the name of the generics to a table, to be used for ptr
                        if inner_index == 0:
                            generics_names.add(inner_child)
                        
                        generic_proc.add(inner_child)
                    
                    generic_proc.add(newEmptyNode())
                    generics.add(generic_proc)
            
        #Add generics to obj type
        obj_type_def.add(generics)

        #Add generics to ptr type
        ptr_type_def.add(generics)

        #Add generics to proc definition
        init_fun.add(generics)
        
        #Initialize them to be bracket expressions
        obj_bracket_expr = nnkBracketExpr.newTree()
        ptr_bracket_expr = nnkBracketExpr.newTree()

        #Add name to brackets
        obj_bracket_expr.add(obj_name)
        ptr_bracket_expr.add(ptr_name)

        for generic_name in generics_names:
            obj_bracket_expr.add(generic_name)
            ptr_bracket_expr.add(generic_name)
        
        #Add the Phasor_obj[T, Y] to ptr_ty, for final statement
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
        init_fun.add(nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("init")
            ),
            newEmptyNode(),
            newEmptyNode()
        )

        #Add the _obj name to ptr_ty
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
    formal_params.add(ptr_bracket_expr)

    #Add obj_type : typedesc[Phasor[T, Y]]
    formal_params.add(nnkIdentDefs.newTree(
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

        formal_params.add(new_arg)

    init_fun.add(formal_params)

    init_fun.add(newEmptyNode())
    init_fun.add(newEmptyNode())

    #Cast and rtalloc operators
    fun_body.add(
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
        fun_body.add(
            nnkAsgn.newTree(
                nnkDotExpr.newTree(
                    newIdentNode("result"),
                    var_name
                ),
                var_name
            )
        )
    
    #Add the function body to the proc declaration
    init_fun.add(fun_body)
    
    #Add everything to result
    final_stmt_list.add(init_fun)
    
    #If using result, it was bugging. Needs to be returned like this to be working properly. don't know why.
    return quote do:
        `final_stmt_list`

#being the argument typed, the code_block is semantically executed after parsing, making it to return the correct result out of the "new" statement
macro executeNewStatementAndBuildUGenObjectType(code_block : typed) : untyped =
    let call_to_new_macro = code_block.last()
    
    return quote do:
        `call_to_new_macro`

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
        template_for_var_declarations = nnkStmtList.newTree()

        empty_var_statements : seq[NimNode]
        call_to_new_macro : NimNode
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
                #Add the ORIGINAL ident name to the array, modifying its name to be "variableName_var"
                var_declarations.add(var_declaration[0])

                #Then, modify the field in the code_block to be "variableName_var"
                code_block[outer_index][inner_index][0] = newIdentNode($(var_declaration[0].strVal()) & "_var")
                
                #Found one! add the sym to seq. It's a nnkIdent.
                if var_declaration[2].kind == nnkEmpty:
                    empty_var_statements.add(var_declaration[0])
        
        #let statements
        elif statement.kind == nnkLetSection:
            for inner_index, let_declaration in statement:
                #Add the ORIGINAL ident name to the array
                let_declarations.add(let_declaration[0])

                #Then, modify the field in the code_block to be "variableName_let"
                code_block[outer_index][inner_index][0] = newIdentNode($(let_declaration[0].strVal()) & "_let")
    
    #Check the variables that are passed to call_to_new_macro
    for index, new_macro_var_name in call_to_new_macro:               #loop over every passed in variables to the "new" call
        for empty_var_statement in empty_var_statements:
            #Trying to pass in an unitialized "var" variable
            if empty_var_statement == new_macro_var_name: #They both are nnkIdents. They can be compared.
                error("\"" & $(empty_var_statement.strVal()) & "\" is a non-initialized variable. It can't be an input to a \"new\" statement.")
        
        #Check if any of the var_declarations are inputs to the "new" macro. If so, append their variable name with "_var"
        for var_declaration in var_declarations:
            if var_declaration == new_macro_var_name:
                #Replace the input to the "new" macro to be "variableName_mut"
                let new_var_declaration = newIdentNode($(var_declaration.strVal()) & "_var")
                
                call_to_new_macro[index] = new_var_declaration

                #[
                    RESULT:
                    template phase() : untyped {.dirty.} =    #The untyped here is fundamental to make this act like a normal text replacement.
                        phase_var[]
                ]#
                #Construct a template that replaces the "variableName" in code with "variableName_var[]", to access the field directly.
                let var_template = nnkTemplateDef.newTree(
                    var_declaration,                        #original name
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

                template_for_var_declarations.add(var_template)
        
        #Check if any of the var_declarations are inputs to the "new" macro. If so, append their variable name with "_let"
        for let_declaration in let_declarations:
            if let_declaration == new_macro_var_name:
                #Replace the input to the "new" macro to be "variableName_let"
                let new_let_declaration = newIdentNode($(let_declaration.strVal()) & "_let")
                
                call_to_new_macro[index] = new_let_declaration

    #echo astGenRepr template_for_var_declarations

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
        if var_name.strVal() != "new": 
            let ugen_asgn_stmt = nnkAsgn.newTree(
                nnkDotExpr.newTree(
                    newIdentNode("ugen"),
                    newIdentNode(var_name.strVal())  #symbol name (ugen.$name)
                ),
                newIdentNode(var_name.strVal())      #symbol name ($name)
            )

            constructor_body.add(ugen_asgn_stmt)

        #First ident == "new"
        else: 
            continue
    
    #The original code block
    let code_block_with_call_to_new_macro = code_block.copy()

    #remove the call to "new" macro from code_block. It will be the body to constructor function.
    code_block.del((code_block.len() - 1))

    result = quote do:
        #templates for substitution on "var" declared variable names in the perform loop
        `template_for_var_declarations`
        
        #With a macro with typed argument, I can just pass in the block of code and it is semantically evaluated. I just need then to extract the result of the "new" statement
        executeNewStatementAndBuildUGenObjectType(`code_block_with_call_to_new_macro`)

        #Actual constructor that returns a UGen... In theory, this allocation should be done with SC's RTAlloc. The ptr to the function should be here passed as arg.
        #export the function to C when building a shared library
        proc UGenConstructor*() : ptr UGen {.exportc: "UGenConstructor".} =
            
            #Variables declaration
            `code_block`

            #Constructor block: allocation of "ugen" variable and assignment of fields
            `constructor_body`

            #Return the "ugen" variable
            return ugen

        #Destructor
        proc UGenDestructor*(ugen : ptr UGen) : void {.exportc: "UGenDestructor".} =
            let ugen_void_cast = cast[pointer](ugen)
            if not ugen_void_cast.isNil():
                rt_free(ugen_void_cast)      #this should be rt_free
            

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
    
    #Add to final obj
    final_obj.add(var_names_and_types)

    return final_type

#Unpack the fields of the ugen. Objects will be passed as unsafeAddr, to get their direct pointers. What about other inbuilt types other than floats, however??n
macro unpackUGenVariables*(t : typed) =
    result = nnkStmtList.newTree()

    var var_section = nnkLetSection.newTree()

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
        
        #ptr and ref types are just passed in as they are:
        #Result
        #someData = ugen.someData_let (or someData_var)
        if var_desc.kind == nnkPtrTy or var_desc.kind == nnkRefTy:
            ident_def_stmt = nnkIdentDefs.newTree(
                newIdentNode(var_name_string[0 .. len(var_name_string) - 5]),   #name of the variable, stripped off the "_var" and "_let" strings
                newEmptyNode(),
                nnkDotExpr.newTree(
                    newIdentNode("ugen"),
                    newIdentNode(var_name_string)                         #name of the variable
                )
            )
        
        #object types will be stripped off their "_var" and "_let" appends, as they will normally be accessed in the code : 
        #Result
        #phasor = unsafeAddr ugen.phasor_let (or phasor_var)
        elif var_desc_type_def.kind != nnkNilLit:
            ident_def_stmt = nnkIdentDefs.newTree(
                newIdentNode(var_name_string[0 .. len(var_name_string) - 5]),   #name of the variable, stripped off the "_var" and "_let" strings
                newEmptyNode(),
                nnkCommand.newTree(
                    newIdentNode("unsafeAddr"),
                    nnkDotExpr.newTree(
                        newIdentNode("ugen"),
                        newIdentNode(var_name_string)                         #name of the variable
                    )
                )
            )

        #inbuilt types return newNilLit
        else:

            #Result:
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
            
            #Result:
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


        var_section.add(ident_def_stmt)

    result.add(var_section)

#Simply cast the inputs from SC in a indexable form in Nim
macro castInsOuts*() =
    return quote do:
        let 
            ins_Nim  {.inject.}  : CFloatPtrPtr = cast[CFloatPtrPtr](ins_SC)
            outs_Nim {.inject.}  : CFloatPtrPtr = cast[CFloatPtrPtr](outs_SC)

#Need to use a template with {.dirty.} pragma to not hygienize the symbols to be like "ugen1123123", but just as written, "ugen".
template perform*(code_block : untyped) {.dirty.} =
    #export the function to C when building a shared library
    proc UGenPerform*(ugen : ptr UGen, buf_size : cint, ins_SC : ptr ptr cfloat, outs_SC : ptr ptr cfloat) : void {.exportc: "UGenPerform".} =    
        
        #Unpack the variables at compile time
        unpackUGenVariables(UGen)

        #cast ins and outs
        castInsOuts()

        #Append the whole code block
        code_block

#Simply wrap the code block in a for loop. Still marked as {.dirty.} to export symbols to context.
template sample*(code_block : untyped) {.dirty.} =
    for audio_index_loop in 0..buf_size:
        code_block