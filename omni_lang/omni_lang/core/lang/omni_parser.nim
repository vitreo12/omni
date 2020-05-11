# MIT License
# 
# Copyright (c) 2020 Francesco Cameli
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#remove tables here and move isStrUpperAscii (and strutils) to another module
import macros, tables, strutils, omni_type_checker, omni_macros_utilities

let non_valid_variable_names {.compileTime.} = [
    "ins", "inputs",
    "outs", "outputs",
    "init", "initialize", "initialise", "build",
    "perform", "sample",
    "sig", "sig32", "sig64",
    "signal", "signal32", "signal64",
    "Data", "Buffer", "Delay"
]

#This is equal to the old isUpperAscii(str) function, which got removed from nim >= 1.2.0
proc isStrUpperAscii(s: string, skipNonAlpha: bool): bool  =
    var hasAtleastOneAlphaChar = false
    if s.len == 0: return false
    for c in s:
        if skipNonAlpha:
            var charIsAlpha = c.isAlphaAscii()
            if not hasAtleastOneAlphaChar:
                hasAtleastOneAlphaChar = charIsAlpha
            if charIsAlpha and (not isUpperAscii(c)):
                return false
        else:
            if not isUpperAscii(c):
                return false
    return if skipNonAlpha: hasAtleastOneAlphaChar else: true

#Node replacement for sample block
proc parse_sample_block(sample_block : NimNode) : NimNode {.compileTime.} =
    return nnkStmtList.newTree(
        nnkCall.newTree(
            newIdentNode("generate_inputs_templates"),
            newIdentNode("omni_inputs"),
            newLit(1),
            newLit(0)
        ),
        nnkCall.newTree(
            newIdentNode("generate_outputs_templates"),
            newIdentNode("omni_outputs")
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

#Find struct calls in a nnkCall and replace them with .new calls.
#To do so, pass a function call here. What is prduced is a when statement that checks
#if the function name + "_obj" is declared, meaning it's a struct constructor the user is trying to call.
#This also covers the Phasor.new() syntax, as the name of the class' only callable function is new_struct anyway.
#e.g.
# Phasor(0.0)  -> when declared(Phasor_obj): Phasor.new_struct(0.0) else: Phasor(0.0)
# myFunc(0.0)  -> when declared(myFunc_obj): myFunc.new_struct(0.0) else: myFunc(0.0)
# Phasor.new() -> when declared(Phasor_obj): Phasor.new_struct() else: Phasor.new()
proc findStructConstructorCall(code_block : NimNode) : NimNode {.compileTime.} =
    if code_block.kind != nnkCall:
        return code_block

    var 
        proc_call_ident = code_block[0]
        proc_call_ident_kind = proc_call_ident.kind

    if proc_call_ident_kind == nnkDotExpr:
        proc_call_ident = proc_call_ident[0]
        proc_call_ident_kind = proc_call_ident.kind
    
    if proc_call_ident_kind != nnkIdent and proc_call_ident_kind != nnkSym:
        return code_block

    let proc_call_ident_obj = newIdentNode(proc_call_ident.strVal() & "_obj")

    var proc_new_call =  nnkCall.newTree(
        newIdentNode("new_struct"),
        proc_call_ident
    )

    for index2, arg in code_block.pairs():
        var arg_temp = arg
        if index2 == 0:
            continue
        
        #Find other constructors in the args of the call
        if arg_temp.kind == nnkCall:
            arg_temp = findStructConstructorCall(arg_temp)
        elif arg_temp.kind == nnkExprEqExpr:
            arg_temp[1] = findStructConstructorCall(arg_temp[1])
        
        proc_new_call.add(arg_temp)
    
    #echo astGenRepr proc_new_call

    #Here it's essential for the when to check for "declared", not "declaredInScope"!
    #declareInScope is useful in init / perform / def bodies for variable declarations
    let when_statement_struct_new = nnkWhenStmt.newTree(
        nnkElifExpr.newTree(
            nnkCall.newTree(
                newIdentNode("declared"),
                proc_call_ident_obj
            ),
            nnkStmtList.newTree(
                proc_new_call
            )
        ),
        nnkElseExpr.newTree(
            nnkStmtList.newTree(
                code_block
            )
        )
    )

    result = when_statement_struct_new

#========================================================================================================================================================#
# EVERYTHING HERE SHOULD BE REWRITTEN, I SHOULDN'T BE LOOPING OVER EVERY SINGLE THING RECURSIVELY, BUT ONLY CONSTRUCTS THAT COULD CONTAIN VAR ASSIGNMENTS
#========================================================================================================================================================#

# ================================ #
# Stage 1: Untyped code generation #
# ================================ #

#Forward declaration
proc parser_dispatcher(statement : NimNode, level : var int) : NimNode {.compileTime.}

#Utility print
proc print_parser_stage(statement : NimNode, level : int) : void {.compileTime.} =
    var val_spaces : string
    for i in 0..level-1:
        val_spaces.add(" ")
    if level == 0:
        echo ""
    echo $val_spaces & $level & ": " & $statement.kind & " -> " & repr(statement)

#Loop around statement and trigger dispatch
proc parser_loop(statement : NimNode, level : var int) : NimNode {.compileTime.} =
    if statement.len > 0:
        for statement_inner in statement:
            var parsed_statement = parser_dispatcher(statement_inner, level)
    return statement

#Parse the call syntax: function(arg)
proc parser_call(statement : NimNode, level : var int) : NimNode {.compileTime.} =
    print_parser_stage(statement, level)
    level += 1
    return parser_loop(statement, level)

#Parse the command syntax: a float
proc parser_command(statement : NimNode, level : var int) : NimNode {.compileTime.} =
    print_parser_stage(statement, level)
    level += 1
    return parser_loop(statement, level)

#Parse the assign syntax: =
proc parse_assign(statement : NimNode, level : var int) : NimNode {.compileTime.} =
    print_parser_stage(statement, level)
    level += 1
    return parser_loop(statement, level)

#Parse the dot syntax: .
proc parse_dot(statement : NimNode, level : var int) : NimNode {.compileTime.} =
    print_parser_stage(statement, level)
    level += 1
    return parser_loop(statement, level)

#Parse the square bracket syntax: []
proc parse_brackets(statement : NimNode, level : var int) : NimNode {.compileTime.} =
    print_parser_stage(statement, level)
    level += 1
    return parser_loop(statement, level)

#Dispatcher logic
proc parser_dispatcher(statement : NimNode, level : var int) : NimNode {.compileTime.} =
    let statement_kind = statement.kind
    
    var parsed_statement : NimNode

    if statement_kind   == nnkCall:
        parsed_statement = parser_call(statement, level)
    elif statement_kind == nnkCommand:
        parsed_statement = parser_command(statement, level)
    elif statement_kind == nnkAsgn:
        parsed_statement = parse_assign(statement, level)
    elif statement_kind == nnkDotExpr:
        parsed_statement = parse_dot(statement, level)
    elif statement_kind == nnkBracketExpr:
        parsed_statement = parse_brackets(statement, level)
    else:
        parsed_statement = parser_loop(statement, level)

    return parsed_statement
    
#Entry point: Parse entire block
proc parse_block(code_block : NimNode, is_constructor_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false) : void {.compileTime.} =
    if code_block.len > 0:
        for index, statement in code_block.pairs():
            let statement_kind = statement.kind

            #Look for "build:" statement. If there are any, it's an error. Only at last position there should be one.
            if is_constructor_block:
                if statement_kind == nnkCall or statement_kind == nnkCommand:
                    let statement_first = statement[0]
                    if statement_first.kind == nnkIdent or statement_first.kind == nnkSym:
                        if statement_first.strVal() == "build":
                           error "init: the \'build\' call, if used, must only be one and at the last position of the \'init\' block."
            
            #Initial level, 0
            var level : int = 0
            let max_level : int = statement.len #useless?
            let parsed_statement = parser_dispatcher(statement, level)

            #Replaced the parsed_statement
            if parsed_statement != nil:
                code_block[index] = parsed_statement








proc parse_block_recursively_for_variables(code_block : NimNode, variable_names_table : TableRef[string, string], is_constructor_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, recursive_outs : bool = false) : void {.compileTime.} =
    if code_block.len > 0:
        for index, statement in code_block.pairs():
            let statement_kind = statement.kind

            #If entry is a var/let declaration (meaning it's already been expressed directly in the code), add its entries to table
            if statement_kind == nnkVarSection or statement_kind == nnkLetSection:
                for var_decl in statement.children():
                    let var_name = var_decl[0].strVal()
                    variable_names_table[var_name] = var_name

            #Look for "build:" statement. If there are any, it's an error. Only at last position there should be one.
            if is_constructor_block:
                if statement_kind == nnkCall or statement_kind == nnkCommand:
                    let statement_first = statement[0]
                    if statement_first.kind == nnkIdent or statement_first.kind == nnkSym:
                        if statement_first.strVal() == "build":
                           error "init: the \'build\' call, if used, must only be one and at the last position of the \'init\' block."

            echo statement_kind
            #a (no types, defaults to float)
            #[ 
            if statement_kind == nnkIdent:
                code_block[index] = nnkVarSection.newTree(
                    nnkIdentDefs.newTree(
                        statement,
                        newIdentNode("float"),
                        newEmptyNode()
                    )
                )  
            ]#

            #look for ins[i]/outs[i] in perform block
            if is_perform_block and statement.len > 1:
                
                #Look for ins[i]
                if statement_kind == nnkBracketExpr: 
                    let 
                        bracket_ident = statement[0]
                        bracket_val   = statement[1]
                    
                    if bracket_ident.kind == nnkIdent:
                        let bracket_ident_str = bracket_ident.strVal()
                        
                        if bracket_ident_str == "ins":
                            var audio_index_loop = newLit(0)
                            
                            if is_sample_block:
                                audio_index_loop = newIdentNode("audio_index_loop")
                            
                            let new_statement = nnkCall.newTree(
                                newIdentNode("get_dynamic_input"),
                                newIdentNode("ins_Nim"),
                                bracket_val,
                                audio_index_loop
                            )

                            code_block[index] = new_statement

                #Look for outs[i] = ... . It needs to be an assignment, and first entry must be a bracket expr!
                elif statement_kind == nnkAsgn and not recursive_outs:
                    var 
                        assgn_left  = statement[0]
                        assgn_right = statement[1]
                    
                    if assgn_left.kind == nnkBracketExpr:
                        
                        let
                            bracket_ident = assgn_left[0]
                            bracket_index = assgn_left[1]
                    
                        if bracket_ident.kind == nnkIdent:
                            #Found it
                            if bracket_ident.strVal() == "outs":
                                var audio_index_loop_bracket : NimNode

                                if is_sample_block:
                                    audio_index_loop_bracket = nnkBracketExpr.newTree(
                                        nnkBracketExpr.newTree(
                                            newIdentNode("outs_Nim"),
                                            nnkCall.newTree(
                                                newIdentNode("int"),
                                                bracket_index
                                            )  
                                        ),
                                        newIdentNode("audio_index_loop")
                                    )
                                else:
                                    audio_index_loop_bracket = nnkBracketExpr.newTree(
                                        newIdentNode("outs_Nim"),
                                        nnkCall.newTree(
                                            newIdentNode("int"),
                                            bracket_index
                                        )
                                    )

                                #echo repr audio_index_loop_bracket

                                var new_statement = nnkStmtList.newTree(
                                    nnkIfStmt.newTree(
                                        nnkElifBranch.newTree(
                                            nnkInfix.newTree(
                                                newIdentNode("<"),
                                                bracket_index,
                                                newIdentNode("omni_outputs")
                                            ),
                                            nnkStmtList.newTree(
                                                nnkAsgn.newTree(
                                                    audio_index_loop_bracket,
                                                    nnkCall.newTree(
                                                        nnkCall.newTree(
                                                            newIdentNode("typeof"),
                                                            audio_index_loop_bracket
                                                    ),
                                                    assgn_right
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )

                                #echo astGenRepr assgn_right

                                #Run the parsing on the assgn_right too, if there are weird assignments / calls / etc...
                                parse_block_recursively_for_variables(assgn_right, variable_names_table, is_constructor_block, is_perform_block, is_sample_block, true)

                                code_block[index] = new_statement
                                
                                #continue! no need to go with all the stuff that follows
                                continue
            
            #Return stmt kind, run constructor checks! (like: return Phasor() should expand Phasor())
            if statement_kind == nnkReturnStmt:
                #empty return
                if statement.len < 1:
                    continue

                var 
                    return_content = statement[0]
                    return_content_kind = return_content.kind

                if return_content_kind == nnkCall:
                    var 
                        new_return_content = findStructConstructorCall(return_content)
                        new_return_stmt = nnkReturnStmt.newTree(
                            new_return_content
                        )

                    code_block[index] = new_return_stmt
                    
            #a : float OR a = 0.5 OR a float = 0.5 OR a : float = 0.5 OR a float
            elif statement_kind == nnkCall or statement_kind == nnkAsgn or statement_kind == nnkCommand:
                
                if statement.len < 2:
                    continue

                var 
                    var_ident = statement[0]
                    var_misc  = statement[1]
                    var_ident_kind = var_ident.kind

                #If an ambiguous openSym... Take the first symbol. Also update var_ident_kind
                if(var_ident_kind == nnkOpenSymChoice):
                    var_ident      = var_ident[0]
                    var_ident_kind = var_ident.kind
                
                var is_no_colon_syntax = false

                #a float = 0.5
                if var_ident_kind == nnkCommand:
                    var_ident = var_ident[0]

                    var_ident_kind = var_ident.kind
                    
                    var_misc = nnkStmtList.newTree(
                        nnkAsgn.newTree(
                            statement[0][1],
                            statement[1]
                        )
                    )
                    
                    is_no_colon_syntax = true

                #a float
                if statement_kind == nnkCommand:
                    var_misc = nnkStmtList.newTree(
                        var_misc
                    )

                    is_no_colon_syntax = true


                if statement_kind == nnkCall:
                    var new_call = findStructConstructorCall(statement)
                    parse_block_recursively_for_variables(new_call, variable_names_table, is_constructor_block, is_perform_block, is_sample_block)
                    echo repr new_call   
                    continue    

                #var_name (used only when var_ident is a nnkIdent type)
                #new_var_statement is the actually code replacement
                var 
                    var_name : string
                    new_var_statement : NimNode

                
                #If dot syntax ("a.b = Vector()") OR array syntax ("data[i] = Vector()").
                if var_ident_kind == nnkDotExpr or var_ident_kind == nnkBracketExpr:

                    #if assignment, a.b = 10, check type of a.b
                    if statement_kind == nnkAsgn:
                        var default_value = var_misc

                        #Find if the = is a nnkCall, if it's so: check if it's a constructor call to a struct.
                        #This is in fact an error, but it will be thrown at the later semantic typed check! 
                        if default_value.kind == nnkCall:
                            default_value = findStructConstructorCall(default_value)

                        new_var_statement = nnkStmtList.newTree(
                            nnkAsgn.newTree(
                                var_ident,
                                nnkCall.newTree(
                                    nnkCall.newTree(
                                        newIdentNode("typeof"),
                                        var_ident
                                    ),
                                    default_value
                                )
                            )
                        )

                    #Find stuff like a.func(Phasor())
                    elif statement_kind == nnkCall:
                        var default_value = var_misc

                        #Find if the = is a nnkCall, if it's so: check if it's a constructor call to a struct.
                        #This is in fact an error, but it will be thrown at the later semantic typed check! 
                        if default_value.kind == nnkCall:
                            default_value = findStructConstructorCall(default_value)

                        new_var_statement = nnkStmtList.newTree(
                            nnkCall.newTree(
                                var_ident,
                                default_value
                            )
                        )

                    #Other kinds of dot expr, like function calls (myVec.set(0.1)). Just continue
                    #else:
                    #    continue

                #Everything else, normal assignments / calls
                else:

                    #Only consider idents at this stage
                    if var_ident_kind == nnkIdent or var_ident_kind == nnkSym:
                        #var_name, only to be used when no nnkDotExpr is used. This here will always be a nnkIdent
                        var_name = var_ident.strVal()
                        
                        #If already there is an entry, skip. Keep the first found one.
                        #if variable_names_table.hasKey(var_name):
                        #    continue

                        #a : float or a : float = 0.0
                        if statement_kind == nnkCall or is_no_colon_syntax:
                            
                            #This is for a : float = 0.0 AND a : float
                            if var_misc.kind == nnkStmtList:
                                
                                if var_misc[0].kind == nnkAsgn: 
                                    let specified_type = var_misc[0][0]  # : float
                                    var default_value  = var_misc[0][1]  # = 0.0

                                    #Find if the = is a nnkCall, if it's so: check if it's a constructor call to a struct
                                    if default_value.kind == nnkCall:
                                        default_value = findStructConstructorCall(default_value)

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
                                    when declaredInScope("phase").not:
                                        phase : ...
                                    else:
                                        {.fatal.} ...
                                ]#
                                new_var_statement = nnkStmtList.newTree(
                                    nnkWhenStmt.newTree(
                                        nnkElifBranch.newTree(
                                            nnkDotExpr.newTree(
                                                nnkCall.newTree(
                                                    newIdentNode("declaredInScope"),
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
                                                        newLit("can't re-define variable \'" & $var_name & "\'. It's already been defined.")
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )

                        #[ else:
                            if var_misc.len > 0:
                                echo astGenRepr var_misc
             ]#
                        #a = 0.0
                        elif statement_kind == nnkAsgn:
                            
                            var default_value = var_misc

                            #Find if the = is a nnkCall, if it's so: check if it's a constructor call to a struct
                            if default_value.kind == nnkCall:
                                default_value = findStructConstructorCall(default_value)

                            #Prevent the user from defining out1, out2... etc...
                            var is_out_variable = false
                            if(var_name.startsWith("out")):
                                #out1 / out10
                                if var_name.len == 4:
                                    if var_name[3].isDigit:
                                        is_out_variable = true
                                elif var_name.len == 5:
                                    if var_name[3].isDigit and var_name[4].isDigit:
                                        is_out_variable = true
                            
                            #not an out1, out2..etc..
                            if not is_out_variable:
                                #var a = 0.0
                                new_var_statement = nnkVarSection.newTree(
                                    nnkIdentDefs.newTree(
                                        var_ident,
                                        newEmptyNode(),
                                        default_value,
                                    )
                                )

                                let
                                    var_name_assignment = new_var_statement[0][0]
                                    var_assign = new_var_statement[0][2]

                                #This is needed to avoid renaming stuff that already had been defined in a previous variable, templates, etc...
                                #[
                                    when declaredInScope("phase").not:
                                        var phase = ...
                                    else:
                                        phase = typeof(phase)(...)
                                ]#
                            
                                new_var_statement = nnkStmtList.newTree(
                                    nnkWhenStmt.newTree(
                                        nnkElifBranch.newTree(
                                            nnkDotExpr.newTree(
                                                nnkCall.newTree(
                                                    newIdentNode("declaredInScope"),
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
                                                    var_name_assignment,
                                                    nnkCall.newTree(
                                                        nnkCall.newTree(
                                                            newIdentNode("typeof"),
                                                            var_name_assignment
                                                        ),
                                                        var_assign
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )

                            #out1 = ... (ONLY in perform / sample blocks)
                            else:
                                if is_perform_block:
                                    let out_var = newIdentNode(var_name)
                                    new_var_statement = nnkAsgn.newTree(
                                        out_var,
                                        nnkCall.newTree(
                                            nnkCall.newTree(
                                                newIdentNode("typeof"),
                                                out_var
                                            ),
                                            default_value
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
            parse_block_recursively_for_variables(statement, variable_names_table, is_constructor_block, is_perform_block, is_sample_block, recursive_outs)
    
    #Reset at end of chain
    #[ else:
        running_index_seq = @[0] ]#

macro parse_block_for_variables*(code_block_in : untyped, is_constructor_block_typed : typed = false, is_perform_block_typed : typed = false, is_sample_block_typed : typed = false, bits_32_or_64_typed : typed = false) : untyped =
    var 
        #used to wrap the whole code_block in a block: statement to create a closed environment to be semantically checked, and not pollute outer scope with symbols.
        final_block = nnkBlockStmt.newTree().add(newEmptyNode())
        code_block  = code_block_in

    let 
        is_constructor_block = is_constructor_block_typed.boolVal()
        is_perform_block = is_perform_block_typed.boolVal()
        is_sample_block = is_sample_block_typed.boolVal()
        bits_32_or_64 = bits_32_or_64_typed.boolVal()
    
    #Using the global variable. Reset it at every call.
    var variable_names_table = newTable[string, string]()

    #Sample block without perform
    if is_sample_block:
        code_block = parse_sample_block(code_block)

    #Standard perform block (is_sample_block is false here too)
    elif is_perform_block:
        var found_sample_block = false
        
        for index, statement in code_block.pairs():
            if statement.kind == nnkCall:
                let var_ident = statement[0]
                let var_misc  = statement[1]
                
                #Look for the sample block inside of perform
                if var_ident.strVal == "sample":
                    let sample_block = var_misc

                    #Replace the sample: block with the new parsed one.
                    code_block[index] = parse_sample_block(sample_block)

                    found_sample_block = true

                    break
            
        #couldn't find sample block IN perform block
        if found_sample_block.not:
            error "perform: no \'sample\' block provided, or not at top level."
        
    
    #Remove new statement from the block before all syntactic analysis.
    #This is needed for this to work:
    #new:
    #   phase
    #   somethingElse
    #This build_statement will then be passed to the next analysis part in order to be re-added at the end
    #of all the parsing.
    var build_statement : NimNode
    if is_constructor_block:
        let code_block_last = code_block.last()
        if code_block_last.kind == nnkCall or code_block_last.kind == nnkCommand:
            let code_block_last_first = code_block_last[0]
            if code_block_last_first.kind == nnkIdent or code_block_last_first.kind == nnkSym:
                if code_block_last_first.strVal() == "build":
                    build_statement = code_block_last
                    code_block.del(code_block.len() - 1) #delete from code_block too. it will added back again later after semantic evaluation.
    
    #Begin parsing
    parse_block(code_block, is_constructor_block, is_perform_block, is_sample_block)

    error("yeah")

    #Look for var  declarations recursively in all blocks
    parse_block_recursively_for_variables(code_block, variable_names_table, is_constructor_block, is_perform_block, is_sample_block)
    
    #Add all stuff relative to initialization for perform function:
    #[
        #Add the templates needed for Omni_UGenPerform to unpack variable names declared with "var" in cosntructor
        generateTemplatesForPerformVarDeclarations()

        #Cast the void* to UGen*
        let ugen = cast[ptr UGen](ugen_ptr)

        #cast ins and outs
        castInsOuts()

        #Unpack the variables at compile time. It will also expand on any Buffer types.
        unpackUGenVariables(UGen)
    ]#
    if is_perform_block:
        var castInsOuts_call = nnkCall.newTree()

        #true == 64, false == 32
        if bits_32_or_64:
            castInsOuts_call.add(newIdentNode("castInsOuts64"))
        else:
            castInsOuts_call.add(newIdentNode("castInsOuts32"))

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
                        newIdentNode("ugen_ptr")
                    )
                )
            ),
            castInsOuts_call,
            nnkCall.newTree(
                newIdentNode("unpackUGenVariables"),
                newIdentNode("UGen")
            ),

            #Re-add code_block
            code_block
        )

    final_block.add(code_block)

    #echo repr code_block

    #echo variable_names_table

    #echo "CODE BLOCK"
    #echo astGenRepr code_block
    #echo astGenRepr final_block

    #echo repr final_block

    #Run the actual macro to subsitute structs with let statements
    return quote do:
        #Need to run through an evaluation in order to get the typed information of the block:
        parse_block_for_consts_and_structs(`final_block`, `build_statement`, `is_constructor_block_typed`, `is_perform_block_typed`)










#========================================================================================================================================================#
# EVERYTHING HERE SHOULD BE REWRITTEN, I SHOULDN'T BE LOOPING OVER EVERY SINGLE THING RECURSIVELY, BUT ONLY CONSTRUCTS THAT COULD CONTAIN VAR ASSIGNMENTS
#========================================================================================================================================================#

proc parse_block_recursively_for_consts_and_structs(typed_code_block : NimNode, templates_to_ignore : TableRef[string, string], is_perform_block : bool = false) : void {.compileTime.} =  
    #Look inside the typed block, which contains info about types, etc...
    for index, typed_statement in typed_code_block.pairs():
        #kind of current inspected block
        let typed_statement_kind = typed_statement.kind

        #Useless types to inspect, skip them
        if typed_statement_kind   == nnkEmpty:
            continue
        elif typed_statement_kind == nnkSym:
            continue
        elif typed_statement_kind == nnkIdent:
            continue

        #Look for templates to ignore
        #[
        if typed_statement_kind == nnkTemplateDef:
            let template_name = typed_statement[0].strVal()
            templates_to_ignore[template_name] = template_name
            continue
        ]#

        #If it's a function call
        if typed_statement_kind == nnkCall:
            if typed_statement[0].kind == nnkSym:
                
                let function_name = typed_statement[0].strVal()

                #Fix Data/Buffer access: from [] = (delay_data, phase, write_value) to delay_data[phase] = write_value
                if function_name == "[]=":                
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

                #Check type of all arguments for other function calls (not array access related) 
                #Ignore function ending in _min_max (the one used for input min/max conditional) OR is not get_dynamic_input
                #THIS IS NOT SAFE! min_max could be assigned by user to another def
                elif typed_statement.len > 1 and not(function_name.endsWith("_min_max")) and not(function_name == "get_dynamic_input"):
                    for i, arg in typed_statement.pairs():
                        #ignore i == 0 (the function_name)
                        if i == 0:
                            continue
                        
                        let arg_type  = arg.getTypeInst().getTypeImpl()
                        
                        #Check validity of each argument to function
                        checkValidType(arg_type, $i, is_proc_call=true, proc_name=function_name)

        #Look for var sections
        elif typed_statement_kind == nnkVarSection:
            let 
                var_symbol = typed_statement[0][0]
                var_type   = var_symbol.getTypeInst().getTypeImpl()
                var_name   = var_symbol.strVal()

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

            if var_name in non_valid_variable_names:
                error("`" & $var_name & "` is an invalid variable name: it's the name of an in-built type.")

            #Check if it's a valid type
            checkValidType(var_type, var_name)

            #Look for consts: capital letters.
            if var_name.isStrUpperAscii(true):
                let old_statement_body = typed_code_block[index][0]

                #Create new let statement
                let new_let_statement = nnkLetSection.newTree(
                    old_statement_body
                )

                #Replace the entry in the untyped block, which has yet to be semantically evaluated.
                typed_code_block[index] = new_let_statement

            #Look for ptr types, structs
            if var_type.kind == nnkPtrTy:
                #Found a struct!
                if var_type.isStruct():
                    let old_statement_body = typed_code_block[index][0]

                    #Detect if it's a non-initialized struct variable (e.g "data Data[float]")
                    if old_statement_body.len == 3:
                        if old_statement_body[2].kind == nnkEmpty:
                            let error_var_name = old_statement_body[0]
                            error("\'" & $error_var_name & "\': structs must be instantiated on declaration.")
                        
                    #All good, create new let statement
                    let new_let_statement = nnkLetSection.newTree(
                        old_statement_body
                    )

                    #Replace the entry in the untyped block, which has yet to be semantically evaluated.
                    typed_code_block[index] = new_let_statement

        #Look for / , div , % , mod and replace them with safediv and safemod
        elif typed_statement_kind == nnkInfix:
            assert typed_statement.len == 3

            let 
                infix_symbol = typed_statement[0]
                infix_str    = infix_symbol.strVal()

            if infix_str == "/" or infix_str == "div":
                typed_code_block[index] = nnkCall.newTree(
                    newIdentNode("safediv"),
                    typed_statement[1],
                    typed_statement[2]
                )

            elif infix_str == "%" or infix_str == "mod":
                typed_code_block[index] = nnkCall.newTree(
                    newIdentNode("safemod"),
                    typed_statement[1],
                    typed_statement[2]
                )

        #Check validity of dot exprs
        elif typed_statement_kind == nnkDotExpr:
            let typed_code_block_kind = typed_code_block.kind
            
            #Spot if trying to assign something to a field of a struct which is a struct! This is an error
            if typed_code_block_kind == nnkAsgn:
                if isStruct(typed_statement):
                    error("\'" & typed_statement.repr & "\': trying to re-assign an already allocated struct field.")
        
        #Run function recursively
        parse_block_recursively_for_consts_and_structs(typed_statement, templates_to_ignore, is_perform_block)

#This allows to check for types of the variables and look for structs to declare them as let instead of var
macro parse_block_for_consts_and_structs*(typed_code_block : typed, build_statement : untyped, is_constructor_block_typed : typed = false, is_perform_block_typed : typed = false) : untyped =
    #Extract the body of the block: [0] is an emptynode
    var inner_block = typed_code_block[1].copy()

    #And also wrap it in a StmtList (if it wasn't a StmtList already)
    if inner_block.kind != nnkStmtList:
        inner_block = nnkStmtList.newTree(inner_block)

    #These are the values extracted from ugen. and general templates. They must be ignored, and their "var" / "let" statement status should be removed
    var templates_to_ignore = newTable[string, string]()
    
    let 
        is_constructor_block = is_constructor_block_typed.strVal() == "true"
        is_perform_block = is_perform_block_typed.strVal() == "true"

    #echo astGenRepr inner_block
    #echo repr inner_block

    parse_block_recursively_for_consts_and_structs(inner_block, templates_to_ignore, is_perform_block)
    
    #Dirty way of turning a typed block of code into an untyped:
    #Basically, what's needed is to turn all newSymNode into newIdentNode.
    #Sym are already semantically checked, Idents are not...
    #Maybe just replace Syms with Idents instead? It would be much safer than this...
    result = typedToUntyped(inner_block)

    #echo repr result

    #if constructor block, run the init_inner macro on the resulting block.
    if is_constructor_block:

        #If old untyped code in constructor constructor had a "build" call as last call, 
        #it must be the old untyped "build" call for all parsing to work properly.
        #Otherwise all the _let / _var declaration in UGen body are screwed
        #If build_statement is nil, it means that it wasn't initialized at it means that there
        #was no "build" call as last statement of the constructor block. Don't add it.
        if build_statement != nil and build_statement.kind != nnkNilLit:
            result.add(build_statement)

        #Run the whole block through the init_inner macro. This will build the actual
        #constructor function, and it will run the untyped version of the "build" macro.
        result = nnkCall.newTree(
            newIdentNode("init_inner"),
            nnkStmtList.newTree(
                result
            )
        )
    
    #echo astGenRepr inner_block
    #echo repr result 