import macros, tables

#Node replacement for sample block
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

proc parse_block_recursively_for_variables(code_block : NimNode, variable_names_table : TableRef[string, string], is_constructor_block : bool = false, is_perform_block : bool = false) : void {.compileTime.} =
    if code_block.len > 0:
        
        for index, statement in code_block.pairs():
            let statement_kind = statement.kind

            #If entry is a var/let declaration (meaning it's already been expressed directly in the code), add its entries to table
            if statement_kind == nnkVarSection or statement_kind == nnkLetSection:
                for var_decl in statement.children():
                    let var_name = var_decl[0].strVal()
                    
                    variable_names_table[var_name] = var_name

            #Look for "build:" statement. If there are any, it's an error. Only at last position there should be.
            if is_constructor_block:
                if statement_kind == nnkCall or statement_kind == nnkCommand:
                    if statement[0].strVal() == "build":
                        error "init: the \"build\" call, if used, must only be one and at the last position of the \"init\" block."


            #a : float or a = 0.5
            if statement_kind == nnkCall or statement_kind == nnkAsgn:

                if statement.len < 2:
                    continue

                let var_ident = statement[0]
                let var_misc  = statement[1]

                let var_ident_kind = var_ident.kind

                #If dot syntax, skip. "a.b = 10". This just sets fields, doesn't assign.
                if var_ident_kind == nnkDotExpr:
                    continue
                
                #If array syntax, skip. "a[i] = 10". This just sets the array entry, doesn't assign.
                if var_ident_kind == nnkBracketExpr:
                    continue

                let var_name = var_ident.strVal

                #If already there is an entry, skip. Keep the first found one.
                if variable_names_table.hasKey(var_name):
                    continue
                
                #And modify source code with the ident node
                var new_var_statement : NimNode

                #a : float or a : float = 0.0
                if statement_kind == nnkCall:
                    
                    #This is for a : float = 0.0 AND a : float
                    if var_misc.kind == nnkStmtList:
                        
                        if var_misc[0].kind == nnkAsgn: 
                            let specified_type = var_misc[0][0]  # : float
                            let default_value  = var_misc[0][1]  # = 0.0

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
                    
                        #This is needed to avoid renaming stuff that already is templates, etc... in perform_block
                        #[
                            when declared("phase").not:
                                phase : ...
                            else:
                                {.fatal.} ...
                        ]#
                        #if is_perform_block:
                        new_var_statement = nnkStmtList.newTree(
                            nnkWhenStmt.newTree(
                                nnkElifBranch.newTree(
                                    nnkDotExpr.newTree(
                                        nnkCall.newTree(
                                            newIdentNode("declared"),
                                            var_ident
                                        ),
                                        newIdentNode("not")
                                    ),
                                    nnkStmtList.newTree(
                                        new_var_statement
                                    )
                                ),
                                nnkElse.newTree(
                                    nnkStmtList.newTree(
                                        nnkPragma.newTree(
                                            nnkExprColonExpr.newTree(
                                                newIdentNode("fatal"),
                                                newLit("can't re-define variable \"" & $var_name & "\". It's already been defined.")
                                            )
                                        )
                                    )
                                )
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

                    #This is needed to avoid renaming stuff that already is templates, etc...
                    #[
                        when declared("phase").not:
                            var phase = ...
                        else:
                            phase = ...
                    ]#
                    #if is_perform_block:
                    new_var_statement = nnkStmtList.newTree(
                        nnkWhenStmt.newTree(
                            nnkElifBranch.newTree(
                                nnkDotExpr.newTree(
                                    nnkCall.newTree(
                                        newIdentNode("declared"),
                                        var_ident
                                    ),
                                    newIdentNode("not")
                                ),
                                nnkStmtList.newTree(
                                    new_var_statement
                                )
                            ),
                            nnkElse.newTree(
                                nnkStmtList.newTree(
                                    nnkAsgn.newTree(
                                        new_var_statement[0][0],
                                        new_var_statement[0][2]
                                    )
                                )
                            )
                        )
                    )
                
                #Add var decl to code_block only if something actually has been assigned to it
                #If using a template (like out1 in sample), new_var_statement would be nil here
                if new_var_statement != nil:

                    #echo repr new_var_statement

                    code_block[index] = new_var_statement

                    #And also to table
                    variable_names_table[var_name] = var_name
                
            #Run the function recursively
            parse_block_recursively_for_variables(statement, variable_names_table, is_perform_block)
    
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
            error "perform: no \"sample\" block provided, or not at top level."
    
    #Remove new statement from the block before all syntactic analysis.
    #This is needed for this to work:
    #new:
    #   phase
    #   somethingElse
    #This build_statement will then be passed to the next analysis part in order to be re-added at the end
    #of all the parsing.
    var build_statement : NimNode
    if is_constructor_block:
        if code_block.last().kind == nnkCall or code_block.last().kind == nnkCommand:
            if code_block.last()[0].strVal() == "build":
                build_statement = code_block.last()
                code_block.del(code_block.len() - 1) #delete from code_block too. it will added back again later after semantic evaluation.
    
    #Look for var  declarations recursively in all blocks
    parse_block_recursively_for_variables(code_block, variable_names_table, is_constructor_block, is_perform_block)
    
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

    final_block.add(code_block)

    #echo variable_names_table

    #echo "CODE BLOCK"
    #echo astGenRepr code_block
    #echo astGenRepr final_block

    #Run the actual macro to subsitute structs with let statements
    return quote do:
        #Need to run through an evaluation in order to get the typed information of the block:
        parse_block_for_structs(`final_block`, `build_statement`, `is_constructor_block_typed`, `is_perform_block_typed`)


#========================================================================================================================================================#
# EVERYTHING HERE SHOULD BE REWRITTEN, I SHOULDN'T BE LOOPING OVER EVERY SINGLE THING RECURSIVELY, BUT ONLY CONSTRUCTS THAT COULD CONTAIN VAR ASSIGNMENTS
#========================================================================================================================================================#

proc parse_block_recursively_for_structs(typed_code_block : NimNode, templates_to_ignore : TableRef[string, string], is_perform_block : bool = false) : void {.compileTime.} =  
    #Look inside the typed block, which contains info about types, etc...
    for index, typed_statement in typed_code_block.pairs():
        let typed_statement_kind = typed_statement.kind

        if typed_statement_kind == nnkEmpty:
            continue

        #Look for templates to ignore
        #[
        if typed_statement_kind == nnkTemplateDef:
            let template_name = typed_statement[0].strVal()
            templates_to_ignore[template_name] = template_name
            continue
        ]#

        #Fix Data/Buffer access: from [] = (delay_data, phase, write_value) to delay_data[phase] = write_value
        if typed_statement_kind == nnkCall:
            if typed_statement[0].kind == nnkSym:
                if typed_statement[0].strVal() == "[]=":                
                    var new_array_assignment : NimNode

                    #1 channel
                    if typed_statement[1].kind == nnkDotExpr:
                        new_array_assignment = nnkAsgn.newTree(
                            nnkBracketExpr.newTree(
                                typed_statement[1],
                                typed_statement[2]
                            ),
                            typed_statement[3]
                        )

                    #Multi channel
                    else:
                        #echo astGenRepr typed_statement

                        let bracket_expr = nnkBracketExpr.newTree(typed_statement[1])
                        
                        #Extract indexes
                        for channel_index in 2..typed_statement.len-2:
                            bracket_expr.add(typed_statement[channel_index])

                        new_array_assignment = nnkAsgn.newTree(
                            bracket_expr,
                            typed_statement.last()
                        )
                    
                    if new_array_assignment != nil:
                        typed_code_block[index] = new_array_assignment
    

        #Look for var sections
        if typed_statement_kind == nnkVarSection:
            let var_symbol = typed_statement[0][0]
            let var_type   = var_symbol.getTypeInst().getTypeImpl()

            #let var_name = var_symbol.strVal()

            #Look for templates to ignore
            #[ 
            if templates_to_ignore.hasKey(var_name):
                echo "Found template: " & $var_name

                #echo astGenRepr typed_statement

                #If found one, remove the var statement (from the untyped section) and use assign instead
                #Look for position in untyped code of this var statement and replace it with assign
                    typed_code_block[index] = nnkAsgn.newTree(
                    newIdentNode(var_name),
                    typed_statement[0][2]
                ) 
            ]#

            #Look for ptr types
            if var_type.kind == nnkPtrTy:
                
                var type_name = var_type[0]

                #generics, extract the name from bracket
                if type_name.kind == nnkBracketExpr:
                    type_name = type_name[0]

                let type_name_str = type_name.strVal
                
                #Found a struct!
                if type_name_str[len(type_name_str) - 4..type_name_str.high] == "_obj":

                    #In perform, allow assignment to already allocated ones, but not creation of new ones (or calling functions that return structs, generally)
                    #This is allowed: a = data  (if data was already allocated in constructor)
                    #This is allowed: a = b.data (if b was already allocated in constructor)
                    #This is not allowed a = Data.init(100)
                    if is_perform_block:
                        let equals_statement_kind = typed_statement[0][2].kind
                        
                        #If not a symbol/ident or a dotexpr, it probably is a function call. Abort!
                        if equals_statement_kind != nnkSym and equals_statement_kind != nnkIdent and equals_statement_kind != nnkDotExpr:
                            error "\"" & $var_symbol.strVal() & "\": structs cannot be allocated in the perform/sample block."

                    let old_statement_body = typed_code_block[index][0]

                    #Create new let statement
                    let new_let_statement = nnkLetSection.newTree(
                        old_statement_body
                    )

                    #Replace the entry in the untyped block, which has yet to be semantically evaluated.
                    typed_code_block[index] = new_let_statement
        
        #Run function recursively
        parse_block_recursively_for_structs(typed_statement, templates_to_ignore, is_perform_block)

#This allows to check for types of the variables and look for structs to declare them as let instead of var
macro parse_block_for_structs*(typed_code_block : typed, build_statement : untyped, is_constructor_block_typed : typed = false, is_perform_block_typed : typed = false) : untyped =
    #Extract the body of the block:. [0] is an emptynode
    var inner_block = typed_code_block[1].copy()

    #These are the values extracted from ugen. and general templates. They must be ignored, and their "var" / "let" statement status should be removed
    var templates_to_ignore = newTable[string, string]()
    
    let 
        is_constructor_block = is_constructor_block_typed.strVal() == "true"
        is_perform_block = is_perform_block_typed.strVal() == "true"

    #echo astGenRepr inner_block
    #echo repr inner_block

    parse_block_recursively_for_structs(inner_block, templates_to_ignore, is_perform_block)
    
    #Dirty way of turning a typed block of code into an untyped:
    #Basically, what's needed is to turn all newSymNode into newIdentNode.
    #Sym are already semantically checked, Idents are not...
    #Maybe just replace Syms with Idents instead? It would be much safer than this...
    result = parseStmt(inner_block.repr())

    #echo repr result

    #if constructor block, run the constructor_inner macro on the resulting block.
    if is_constructor_block:

        #If old untyped code in constructor constructor had a "build" call as last call, 
        #it must be the old untyped "build" call for all parsing to work properly.
        #Otherwise all the _let / _var declaration in UGen body are screwed
        #If build_statement is nil, it means that it wasn't initialized at it means that there
        #was no "build" call as last statement of the constructor block. Don't add it.
        if build_statement != nil and build_statement.kind != nnkNilLit:
            result.add(build_statement)

        
        #Run the whole block through the constructor_inner macro. This will build the actual
        #constructor function, and it will run the untyped version of the "build" macro.
        result = nnkCall.newTree(
            newIdentNode("constructor_inner"),
            nnkStmtList.newTree(
                result
            )
        )
    
    #echo astGenRepr inner_block
    #echo repr result 