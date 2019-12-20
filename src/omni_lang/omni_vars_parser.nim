import macros, tables
    
macro parse_block_for_variables*(code_block : untyped) : untyped =
    var 
        #used to wrap the whole code_block in a block: statement to create a closed environment to be semantically checked, and not pollute outer scope with symbols.
        final_block = nnkBlockStmt.newTree().add(newEmptyNode())

        #Using table as an identity dictionary
        variablesToDeclare_table = initTable[string, string]()

    for index, statement in code_block.pairs():
        let statement_kind = statement.kind

        #a : float or a = 0.5
        if statement_kind == nnkCall or statement_kind == nnkAsgn:
            let var_ident = statement[0]
            let var_misc  = statement[1]
            
            let var_name = var_ident.strVal

            #If already there is an entry, skip. Keep the first found one.
            if variablesToDeclare_table.hasKey(var_name):
                continue
            
            #And modify source code with the ident node
            var new_var_statement : NimNode

            #a : float or a : float = 0.0
            if statement_kind == nnkCall:
                
                #This is for a : float = 0.0
                if var_misc.kind == nnkStmtList:
                    if var_misc[0].kind == nnkAsgn: 
                        let specified_type = var_misc[0][0]  # : float
                        let default_value  = var_misc[0][1]  # = 0.0
                        
                        #var a : float = 0.0
                        new_var_statement = nnkVarSection.newTree(
                            nnkIdentDefs.newTree(
                                var_ident,
                                specified_type,
                                default_value
                            )
                        )

                    else:
                        let specified_type = var_misc[0]  # : float

                        #var a : float
                        new_var_statement = nnkVarSection.newTree(
                            nnkIdentDefs.newTree(
                                var_ident,
                                specified_type,
                                newEmptyNode()
                            )
                        )
            
            #a = 0.0
            else:
                let default_value = var_misc

                #var a = 0.0
                new_var_statement = nnkVarSection.newTree(
                    nnkIdentDefs.newTree(
                        var_ident,
                        newEmptyNode(),
                        default_value,
                    )
                )
            
            #Add var decl to code_block
            code_block[index] = new_var_statement

            #And also to table
            variablesToDeclare_table[var_name] = var_name

    #Wrap everything into a block: statement to create a different scope
    final_block.add(code_block)
    
    #echo astGenRepr code_block
    #echo astGenRepr final_block

    #Run the actual macro to subsitute structs with let statements
    return quote do:
        #Need to run through an evaluation in order to get the typed information of the block:
        parse_block_for_structs(`final_block`, `code_block`)

#This allows to check for types of the variables and look for structs to declare them as let instead of var
macro parse_block_for_structs*(typed_code_block : typed, untyped_block_code : untyped, is_perform_block_typed : typed = false) : untyped =
    #This is what will be returned: a new untyped block
    result = untyped_block_code

    #Extract the body of the block:. [0] is an emptynode
    let inner_block = typed_code_block[1]

    let is_perform_block = is_perform_block_typed.boolVal()

    #Look inside the typed block, which contains info about types, etc...
    for index, statement in inner_block.pairs():
        let statement_kind = statement.kind

        #Look for var sections
        if statement_kind == nnkVarSection:
            var var_symbol = statement[0][0]
            let var_type   = var_symbol.getTypeInst().getTypeImpl()

            #Look for ptr types
            if var_type.kind == nnkPtrTy:
                
                var type_name = var_type[0]

                #generics, extract the name from bracket
                if type_name.kind == nnkBracketExpr:
                    type_name = type_name[0]

                let type_name_str = type_name.strVal
                
                #Found a struct!
                if type_name_str[len(type_name_str) - 4..type_name_str.high] == "_obj":

                    if is_perform_block:
                        error "Structs cannot be allocated in the perform/sample block."

                    let old_statement_body = result[index][0]

                    #Create new let statement
                    let new_let_statement = nnkLetSection.newTree(
                        old_statement_body
                    )

                    #Replace the entry in the untyped block, which has yet to be semantically evaluated.
                    result[index] = new_let_statement
    
    #echo astGenRepr inner_block
    #echo astGenRepr result 