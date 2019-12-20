import macros, tables

#Text replacement for sample block
proc parse_sample_block(sample_block : NimNode) : NimNode {.compileTime.} =
    return nnkStmtList.newTree(
        nnkCall.newTree(
          newIdentNode("generate_inputs_templates"),
          newIdentNode("ugen_inputs"),
          newLit(1)
        ),
        nnkCall.newTree(
          newIdentNode("generate_outputs_templates"),
          newIdentNode("ugen_outputs"),
          newLit(1)
        ),
        nnkForStmt.newTree(
          newIdentNode("audio_index_loop"),
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
          sample_block
        ),
        nnkLetSection.newTree(
          nnkIdentDefs.newTree(
            newIdentNode("audio_index_loop"),
            newEmptyNode(),
            newLit(0)
          )
        )
      )

#========================================================================================================================================================#
# EVERYTHING HERE SHOULD BE REWRITTEN, I SHOULDN'T BE LOOPING OVER EVERY SINGLE THING RECURSIVELY, BUT ONLY CONSTRUCTS THAT COULD CONTAIN VAR ASSIGNMENTS
#========================================================================================================================================================#

proc parse_block_recursively_for_variables(code_block : NimNode, variable_names_table : TableRef[string, string]) : void {.compileTime.} =
    if code_block.len > 0:
        
        for index, statement in code_block.pairs():
            let statement_kind = statement.kind

            #If entry is a var/let declaration (meaning it's already been expressed directly in the code), add its entries to table
            if statement_kind == nnkVarSection or statement_kind == nnkLetSection:
                for var_decl in statement.children():
                    let var_name = var_decl[0].strVal()
                    
                    variable_names_table[var_name] = var_name

            #a : float or a = 0.5
            if statement_kind == nnkCall or statement_kind == nnkAsgn:

                if statement.len < 2:
                    continue

                let var_ident = statement[0]
                let var_misc  = statement[1]

                #If dot syntax, skip. "a.b = 10". This just sets fields, doesn't assign.
                if var_ident.kind == nnkDotExpr:
                    continue
                
                let var_name = var_ident.strVal

                #If already there is an entry, skip. Keep the first found one.
                if variable_names_table.hasKey(var_name):
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

                            #WHEN statement for perform block:
                            
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

                            #WHEN statement for perform block:

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

                    #WHEN statement for perform block:

                    #var a = 0.0
                    new_var_statement = nnkVarSection.newTree(
                        nnkIdentDefs.newTree(
                            var_ident,
                            newEmptyNode(),
                            default_value,
                        )
                    )
                
                #Add var decl to code_block only if something actually has been assigned to it
                #If using a template (like out1 in sample), new_var_statement would be nil here
                if new_var_statement != nil:
                    code_block[index] = new_var_statement

                    #echo var_name

                    #And also to table
                    variable_names_table[var_name] = var_name
                
            #Run the function recursively
            parse_block_recursively_for_variables(statement, variable_names_table)
    
    #Reset at end of chain
    #[ else:
        running_index_seq = @[0] ]#

macro parse_block_for_variables*(code_block_in : untyped, is_constructor_block_typed : typed = false, is_perform_block_typed : typed = false) : untyped =
    var 
        #used to wrap the whole code_block in a block: statement to create a closed environment to be semantically checked, and not pollute outer scope with symbols.
        final_block = nnkBlockStmt.newTree().add(newEmptyNode())
        code_block  = code_block_in

    let 
        is_constructor_block = is_constructor_block_typed.boolVal()
        is_perform_block = is_perform_block_typed.boolVal()
    
    #Using the global variable. Reset it at every call.
    var variable_names_table = newTable[string, string]()

    #Find sample block:
    if is_perform_block:
        var found_sample_block = false
        for index, statement in code_block.pairs():
            if statement.kind == nnkCall:
                let var_ident = statement[0]
                let var_misc  = statement[1]
                
                #Found it!
                if var_ident.strVal == "sample":
                    let sample_block = var_misc

                    #Replace the sample: block with the new parsed one.
                    code_block[index] = parse_sample_block(sample_block)

                    #echo astGenRepr code_block[index]
                    
                    found_sample_block = true

                    break
            
        #couldn't find sample block
        if found_sample_block.not:
            error "perform: no \"sample\" block provided"

    #Add all stuff relative to initialization for perform function:
    #[
        #Add the templates needed for UGenPerform to unpack variable names declared with "var" in cosntructor
        generateTemplatesForPerformVarDeclarations()

        #Cast the void* to UGen*
        let ugen = cast[ptr UGen](ugen_void)

        #cast ins and outs
        castInsOuts()

        #Unpack the variables at compile time. It will also expand on any Buffer types.
        unpackUGenVariables(UGen)
    ]#
    if is_perform_block:
        code_block = nnkStmtList.newTree(
            nnkCall.newTree(
                newIdentNode("generateTemplatesForPerformVarDeclarations")
            ),
            nnkLetSection.newTree(
                nnkIdentDefs.newTree(
                    newIdentNode("ugen"),
                    newEmptyNode(),
                    nnkCast.newTree(
                        nnkPtrTy.newTree(
                            newIdentNode("UGen")
                        ),
                        newIdentNode("ugen_void")
                    )
                )
            ),
            nnkCall.newTree(
                newIdentNode("castInsOuts")
            ),
            nnkCall.newTree(
                newIdentNode("unpackUGenVariables"),
                newIdentNode("UGen")
            ),

            #Re-add code_block
            code_block
        )

    #Look for var  declarations recursively in all blocks
    parse_block_recursively_for_variables(code_block, variable_names_table)
        
    final_block.add(code_block)

    echo variable_names_table

    #echo "CODE BLOCK"
    #echo astGenRepr code_block
    #echo astGenRepr final_block

    #Run the actual macro to subsitute structs with let statements
    return quote do:
        #Need to run through an evaluation in order to get the typed information of the block:
        parse_block_for_structs(`final_block`, `code_block`, `is_constructor_block_typed`, `is_perform_block_typed`)


#========================================================================================================================================================#
# EVERYTHING HERE SHOULD BE REWRITTEN, I SHOULDN'T BE LOOPING OVER EVERY SINGLE THING RECURSIVELY, BUT ONLY CONSTRUCTS THAT COULD CONTAIN VAR ASSIGNMENTS
#========================================================================================================================================================#

proc parse_block_recursively_for_structs(typed_code_block : NimNode, untyped_code_block : NimNode, templates_to_ignore : TableRef[string, string], is_perform_block : bool = false) : void {.compileTime.} =
    
    if typed_code_block.len > 0:
        
        #Look inside the typed block, which contains info about types, etc...
        for index, typed_statement in typed_code_block.pairs():
            let typed_statement_kind = typed_statement.kind

            if typed_statement_kind == nnkEmpty:
                continue

            #Look for templates to ignore
            if typed_statement_kind == nnkTemplateDef:
                let template_name = typed_statement[0].strVal()
                templates_to_ignore[template_name] = template_name
                continue

            #Look for var sections
            if typed_statement_kind == nnkVarSection:
                let var_symbol = typed_statement[0][0]
                let var_type   = var_symbol.getTypeInst().getTypeImpl()

                let var_name = var_symbol.strVal()

                #Look for templates to ignore
                if templates_to_ignore.hasKey(var_name):
                    echo "Found template: " & $var_name

                    #echo astGenRepr typed_statement

                    #If found one, remove the var statement (from the untyped section) and use assign instead
                    #Look for position in untyped code of this var statement and replace it with assign
                    #[ typed_code_block[index] = nnkAsgn.newTree(
                        newIdentNode(var_name),
                        typed_statement[0][2]
                    ) ]#

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
                            error "\"" & $var_symbol.strVal() & "\": structs cannot be allocated in the perform/sample block."

                        let old_statement_body = untyped_code_block[index][0]

                        #Create new let statement
                        let new_let_statement = nnkLetSection.newTree(
                            old_statement_body
                        )

                        #Replace the entry in the untyped block, which has yet to be semantically evaluated.
                        untyped_code_block[index] = new_let_statement
        
            #Run function recursively
            parse_block_recursively_for_structs(typed_statement, untyped_code_block, templates_to_ignore, is_perform_block)

#This allows to check for types of the variables and look for structs to declare them as let instead of var
macro parse_block_for_structs*(typed_code_block : typed, untyped_code_block : untyped, is_constructor_block_typed : typed = false, is_perform_block_typed : typed = false) : untyped =
    #This is what will be returned: a new untyped block
    result = untyped_code_block

    #Extract the body of the block:. [0] is an emptynode
    var inner_block = typed_code_block[1]

    #These are the values extracted from ugen. and general templates. They must be ignored, and their "var" / "let" statement status should be removed
    var templates_to_ignore = newTable[string, string]()
    
    let 
        is_constructor_block = is_constructor_block_typed.strVal() == "true"
        is_perform_block = is_perform_block_typed.strVal() == "true"

    #echo astGenRepr inner_block
    #echo variable_names_table
    #echo astGenRepr inner_block[0]

    #echo "RESULT"
    #echo astGenRepr result

    parse_block_recursively_for_structs(inner_block, result, templates_to_ignore, is_perform_block)
    
    #if constructor block, run the constructor_inner macro on the resulting block.
    if is_constructor_block:
        result = nnkCall.newTree(
            newIdentNode("constructor_inner"),
            nnkStmtList.newTree(
                result
            )
        )

    #echo astGenRepr inner_block
    #echo astGenRepr result 