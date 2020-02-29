import macros

macro def*(function_signature : untyped, code_block : untyped) : untyped =
    var 
        proc_def = nnkProcDef.newTree()
        proc_return_type : NimNode
        proc_name : NimNode
        proc_generic_params = nnkGenericParams.newTree()
        proc_formal_params  = nnkFormalParams.newTree()
        
        #Pass the proc body to the parse_block_for_variables macro to avoid var/let declarations
        proc_body = nnkStmtList.newTree(
            nnkCall.newTree(
                newIdentNode("parse_block_for_variables"),
                code_block
            )
        )   
    
    let function_signature_kind = function_signature.kind

    if function_signature_kind == nnkCommand or function_signature_kind == nnkObjConstr or function_signature_kind == nnkCall or function_signature_kind == nnkInfix:
        
        var name_with_args : NimNode

        #Missing the return type entirely OR not providing any infos at all.
        #Defaults to returning auto. This also allows void for no return specified.
        if function_signature_kind == nnkObjConstr or function_signature_kind == nnkCall:
            name_with_args = function_signature
            proc_return_type = newIdentNode("auto")
        
        elif function_signature_kind == nnkCommand:
            name_with_args   = function_signature[0]
            proc_return_type = function_signature[1]
        
        elif function_signature_kind == nnkInfix:
            
            if function_signature[0].strVal() != "->":
                error "def: invalid return operator: \"" & $function_signature[0] & "\". Use \"->\"."
            
            name_with_args   = function_signature[1]
            proc_return_type = function_signature[2]

        let first_statement = name_with_args[0]
        
        #Generics
        if first_statement.kind == nnkBracketExpr:
            for index, entry in first_statement.pairs():
                #Name of function
                if index == 0:
                    proc_name = entry
                    continue

                if entry.kind == nnkExprColonExpr:
                    error "def: can't specify generics value \"" & $entry[0].strVal & " : " & $entry[1].strVal & "\" for \"def " & $proc_name.strVal & "\". It is defaulted to be \"SomeNumber\"."
                
                #Generics (for now) can only be SomeNumber
                proc_generic_params.add(
                    nnkIdentDefs.newTree(
                        entry,
                        newIdentNode("SomeNumber"),
                        newEmptyNode()
                    )
                )
        
        #No Generics
        elif first_statement.kind == nnkIdent:
            proc_name = first_statement

        #Formal params
        proc_formal_params.add(proc_return_type)    
        
        let args_block = name_with_args[1..name_with_args.len-1]
    
        for index, statement in args_block.pairs():
            
            var new_arg : NimNode

            let statement_kind = statement.kind

            #float a = 0.5 -> a : float = 0.5 / a = 0.5 -> a : auto = 0.5
            if statement_kind == nnkExprEqExpr:                
                assert statement.len == 2

                var 
                    arg_name : NimNode
                    arg_type : NimNode
                    arg_value : NimNode

                #float a = 0.5
                if statement[0].kind == nnkCommand:
                    assert statement[0].len == 2
                    
                    arg_name = statement[0][1]
                    arg_type = statement[0][0]
                
                #a = 0.5
                else:
                    arg_name = statement[0]
                    arg_type = newIdentNode("auto")
                
                arg_value = statement[1]

                new_arg = nnkIdentDefs.newTree(
                    arg_name,
                    arg_type,
                    arg_value
                )
            
            #float a -> a : float
            elif statement_kind == nnkCommand:
                
                assert statement.len == 2

                new_arg = nnkIdentDefs.newTree(
                    statement[1],
                    statement[0],
                    newEmptyNode()
                )
            
            #a -> a : auto
            elif statement_kind == nnkIdent:
                new_arg = nnkIdentDefs.newTree(
                    statement,
                    newIdentNode("auto"),
                    newEmptyNode()
                )

            else:
                error("\"def " & $proc_name.strVal() & "\": Invalid argument, \"" & $(repr statement) & "\"")

            #[
            #Not specified kind, defaults to auto: def sine(a) -> proc sine(a : auto)
            elif statement_kind != nnkExprColonExpr:

                #def sine(a)
                if statement.len == 0:
                    new_arg = nnkIdentDefs.newTree(
                        statement,
                        newIdentNode("auto"),
                        newEmptyNode()
                    )
                
                #[
                #def sine(a 0.0):
                elif statement.len == 2:
                    new_arg = nnkIdentDefs.newTree(
                        statement[0],
                        newIdentNode("auto"),
                        statement[1]
                    )
                ]#
            
            #def sin(a : float)
            else:
                let arg_name = statement[0]
                let arg_type = statement[1]

                #providing default value
                if arg_type.kind == nnkCommand:
                    if arg_type.len == 2:
                        new_arg = nnkIdentDefs.newTree(
                            arg_name,
                            arg_type[0],
                            arg_type[1]
                        )
                
                #no default value
                else:
                    new_arg = nnkIdentDefs.newTree(
                        arg_name,
                        arg_type,
                        newEmptyNode()
                    )
            ]#
                    
            #echo astGenRepr new_arg

            proc_formal_params.add(new_arg)
                
        #Add name of func
        proc_def.add(proc_name)

        #Add generics
        if proc_generic_params.len > 0:
            proc_def.add(newEmptyNode())
            proc_def.add(proc_generic_params)
        else:
            proc_def.add(newEmptyNode())
            proc_def.add(newEmptyNode())
        
        #Add formal args
        proc_def.add(proc_formal_params)
        proc_def.add(newEmptyNode())
        proc_def.add(newEmptyNode())
        
        #Add function body (with checks for var/lets macro)
        proc_def.add(proc_body)

        #echo astGenRepr proc_def
        #echo repr proc_def        
             
    else:
        error "Invalid syntax for def"

    return proc_def