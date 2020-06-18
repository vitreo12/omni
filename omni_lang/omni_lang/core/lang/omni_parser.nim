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
import macros, strutils, omni_type_checker, omni_macros_utilities

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
#if the function name + "_struct_inner" is declared, meaning it's a struct constructor the user is trying to call.
#This also covers the Phasor.new() syntax, as the name of the class' only callable function is struct_new anyway.
#e.g.
# Phasor(0.0)  -> when declared(Phasor_struct_inner): Phasor.struct_new(0.0) else: Phasor(0.0)
# myFunc(0.0)  -> when declared(myFunc_struct_inner): myFunc.struct_new(0.0) else: myFunc(0.0)
# Phasor.new() -> when declared(Phasor_struct_inner): Phasor.struct_new() else: Phasor.new()

# ALSO GENERICS: (Data has a different behaviour)
# Phasor[float]() -> when declared(Phasor_struct_inner) : Phasor[float].struct_new() else: Phasor[float]()
# Data[int](10) -> when declared(Data_struct_inner) : Data.struct_new(10, dataType=int) else: Data[int](10)
proc findStructConstructorCall(statement : NimNode) : NimNode {.compileTime.} =
    if statement.kind != nnkCall:
        return statement

    var parsed_statement = statement

    var 
        proc_call_ident = parsed_statement[0]
        proc_call_ident_kind = proc_call_ident.kind

    #Dot expr would be Data.new() or something.perform() and Data[float].new() etc.
    if proc_call_ident_kind == nnkDotExpr or proc_call_ident_kind == nnkBracketExpr:
        proc_call_ident = proc_call_ident[0]

        #Only allow .new() methods to be run on structs, no other one is supported.
        #This doesn't work as of now, as it also would not allow to run functions with dot (like, buffer.read())
        #[
        if proc_call_ident_kind == nnkDotExpr:
            var dot_expr_function = parsed_statement[0][1]
            if dot_expr_function.kind == nnkSym or dot_expr_function.kind == nnkIdent:
                let dot_expr_function_str = dot_expr_function.strVal()
                if dot_expr_function_str != "new":
                    error("Undefined function '" & $dot_expr_function_str & "' for '" & (repr(proc_call_ident)) & "'")
        ]#

        proc_call_ident_kind = proc_call_ident.kind
        
        #This happens for Data[float].new
        if proc_call_ident_kind == nnkBracketExpr:
            proc_call_ident = proc_call_ident[0]
            proc_call_ident_kind = proc_call_ident.kind
    
    if proc_call_ident_kind != nnkIdent and proc_call_ident_kind != nnkSym:
        return statement

    var proc_call_ident_str = proc_call_ident.strVal()

    let proc_call_ident_obj = newIdentNode(proc_call_ident_str & "_struct_inner")

    var proc_new_call =  nnkCall.newTree(
        newIdentNode("struct_new"),
        proc_call_ident
    )

    var data_bracket_expr = false

    for index, arg in statement.pairs():
        var arg_temp = arg
        
        if index == 0:
            #This happens for Data[float].new() or Phasor[float].new()
            if arg_temp.kind == nnkDotExpr:
                arg_temp = arg_temp[0]

            #Look for Data[int](10) OR Phasor[int]() syntax
            if arg_temp.kind == nnkBracketExpr:
                #Data case
                if proc_call_ident_str == "Data":
                    data_bracket_expr = true
                
                #Other struct case, use the bracket expr instead of just the ident Phasor[int].struct_new instead of Phasor.struct_new
                else:
                    proc_new_call[1] = arg_temp

            #Continue in any case: the ident name it's already been added
            continue
        
        #Find other constructors in the args of the call, including the one expressed like: arg=value (nnkExprEqExpr)
        if arg_temp.kind == nnkCall:
            arg_temp = findStructConstructorCall(arg_temp)
        elif arg_temp.kind == nnkExprEqExpr:
            arg_temp[1] = findStructConstructorCall(arg_temp[1])

        #Add the new parsed struct call
        proc_new_call.add(arg_temp)
    
    #Need to prepend after all the dataType=int call
    if data_bracket_expr:
        var 
            parsed_statement_bracket = parsed_statement[0] #This is Data[int]
            data_generics = parsed_statement_bracket[1]    #This is just int

        #If new statement with dot expr, retrieve the data_generics from the statement
        if data_generics.kind == nnkIdent:
            if data_generics.strVal() == "new":
                #Go one level down from the dot expr
                parsed_statement_bracket = parsed_statement_bracket[0]
                
                #Not a generics call,perhaps doing some weird stuff.
                if parsed_statement_bracket.kind != nnkBracketExpr:
                    error("Invalid generics call for '" & $proc_call_ident_str & "'")
                
                #Updata data_generics with first bracket entry (index 0 is Data)
                data_generics = parsed_statement_bracket[1]
        
        #If more than 2 (meaning: Data[int, float], as Data is index 0) error out!
        if parsed_statement_bracket.len > 2:
            error astGenRepr parsed_statement_bracket
            error("Cannot instantiate `Data`: got more than one type.")
            
        proc_new_call.add(nnkExprEqExpr.newTree(
                newIdentNode("dataType"),
                data_generics
            )
        )

    #error repr proc_new_call

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
                statement
            )
        )
    )

    result = when_statement_struct_new

# ================================ #
# Stage 1: Untyped code generation #
# ================================ #

#Forward declaration
proc parser_untyped_dispatcher(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.}

#Utility print
proc print_parser_stage(statement : NimNode, level : int) : void {.compileTime.} =
    var val_spaces : string
    for i in 0..level-1:
        val_spaces.add(" ")
    if level == 0:
        echo ""
    echo $val_spaces & $level & ": " & $statement.kind & " -> " & repr(statement)

#Loop around statement and trigger dispatch, performing code substitution
proc parser_untyped_loop(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    var parsed_statement = statement
    if statement.len > 0:
        for index, statement_inner in statement.pairs():
            #Substitute old content with the parsed one
            parsed_statement[index] = parser_untyped_dispatcher(statement_inner, level, is_constructor_block, is_perform_block, is_sample_block, is_def_block)
    return parsed_statement

#Parse the call syntax: function(arg)
proc parse_untyped_call(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    #print_parser_stage(statement, level)
    level += 1

    #Parse the call
    var parsed_statement = parser_untyped_loop(statement, level, is_constructor_block, is_perform_block, is_sample_block, is_def_block)

    #Something weird happened with Data[Something]() in a def.. It returned a call to a
    #nnkOpenSymChoice with symbols.. Re-interpret it and re-run parser (NEEDS MORE TESTING!)
    if parsed_statement[0].kind == nnkCall:
        if parsed_statement[0][0].kind == nnkOpenSymChoice:
            var new_statement = typedToUntyped(parsed_statement)
            parsed_statement = parser_untyped_loop(new_statement, level, is_constructor_block, is_perform_block, is_sample_block, is_def_block)
            
    #Detect constructor calls
    parsed_statement = findStructConstructorCall(parsed_statement)

    #error repr parsed_statement

    return parsed_statement

#Parse the eq expr syntax, Test(data=Data())
proc parse_untyped_expr_eq_expr(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    #print_parser_stage(statement, level)
    level += 1

    var parsed_statement = parser_untyped_loop(statement, level, is_constructor_block, is_perform_block, is_sample_block, is_def_block)

    return parsed_statement

#Parse the command syntax: a float
proc parse_untyped_command(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    #print_parser_stage(statement, level)
    level += 1

    var parsed_statement = statement

    #If top level, it's a declaration. 
    #level == 1 equals to top level here, as the increment is done before parsing.
    if level == 1:
        parsed_statement = nnkVarSection.newTree(
            nnkIdentDefs.newTree(
                parsed_statement[0],
                parsed_statement[1],
                newEmptyNode()
            )
        )
    
    #HERE I CAN ADD NORMAL COMMAND STUFF SO THAT IT'S PERHAPS POSSIBLE TO ENABLE, BY TURNING IT INTO CALLS: print "hello" -> print("hello")
    else:
        discard
    
    return parsed_statement

#Parse the assign syntax: a float = 10 OR a = 10
proc parse_untyped_assign(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    #print_parser_stage(statement, level)
    level += 1

    if statement.len > 3:
        error("Invalid variable assignment.")

    var 
        parsed_statement = parser_untyped_loop(statement, level, is_constructor_block, is_perform_block, is_sample_block, is_def_block)
        assgn_left : NimNode
        assgn_right : NimNode
        is_command_or_ident = false
        is_outs_brackets    = false
        bracket_ident : NimNode
        bracket_index : NimNode

    if parsed_statement.len > 1:
        assgn_left  = parsed_statement[0]
        assgn_right = parsed_statement[1]

        let assgn_left_kind = assgn_left.kind
        
        #Tryin to declare a variable named "tuple" or "type"
        if assgn_left_kind == nnkTupleClassTy:
            error("Can't declare a variable named 'tuple'. It's a keyword for internal use.")
        elif assgn_left_kind == nnkTypeClassTy:
            error("Can't declare a variable named 'type'. It's a keyword for internal use.")
        
        #Command assignment: a float = 0.0
        if assgn_left_kind == nnkCommand:

            if assgn_left.len != 2:
                error("Invalid variable type declaration.")

            assgn_left = nnkIdentDefs.newTree(
                assgn_left[0],
                assgn_left[1],
                assgn_right
            )

            is_command_or_ident = true
        
        #All other cases: normal ident (a = 10), bracket (a[i] = 10), dot (a.b = 10)
        else:
            #Normal assignment: a = 0.0
            if assgn_left_kind == nnkIdent:
                is_command_or_ident = true
            
            #Look for outs[i] in perform block
            elif is_perform_block and assgn_left_kind == nnkBracketExpr:
                bracket_ident = assgn_left[0]
                bracket_index = assgn_left[1]
                if bracket_ident.kind == nnkIdent:
                    if bracket_ident.strVal() == "outs":
                        is_outs_brackets = true

            assgn_left = nnkIdentDefs.newTree(
                assgn_left,
                newEmptyNode(),
                assgn_right
            )

    if assgn_left != nil:
        let var_name     = assgn_left[0]
 
        var var_name_str : string

        if var_name.kind == nnkIdent:
            var_name_str = var_name.strVal()
        
        #look for out1.. etc to perform typeof
        var is_out_variable = false
        
        if(var_name_str.startsWith("out")):
            #out1.. / out10..
            if var_name_str.len == 4:
                if var_name_str[3].isDigit:
                    is_out_variable = true
            elif var_name.len == 5:
                if var_name_str[3].isDigit and var_name_str[4].isDigit:
                    is_out_variable = true
        
        #can't define a variable as in1, in2, etc...
        elif(var_name_str.startsWith("in")):
            #in1.. / in10..
            if var_name_str.len == 3:
                if var_name_str[2].isDigit:
                    error("Trying to redefine input variable: '" & $var_name_str & "'")
            elif var_name_str.len == 4:
                if var_name_str[2].isDigit and var_name_str[3].isDigit:
                    error("Trying to redefine input variable: '" & $var_name_str & "'")
        
        if is_command_or_ident:
            if not is_out_variable:
                #constructor / def
                if is_perform_block.not and is_sample_block.not:
                #if is_constructor_block or is_def_block:
                    parsed_statement = nnkStmtList.newTree(
                        nnkWhenStmt.newTree(
                            nnkElifBranch.newTree(
                                nnkCall.newTree(
                                    newIdentNode("not"),
                                    nnkCall.newTree(
                                        newIdentNode("declaredInScope"),
                                        var_name
                                    ),
                                ),
                                nnkStmtList.newTree(
                                    nnkVarSection.newTree(
                                        assgn_left
                                    )
                                )
                            ),
                            nnkElse.newTree(
                                nnkStmtList.newTree(
                                    nnkAsgn.newTree(
                                        var_name,
                                        nnkCall.newTree(
                                            nnkCall.newTree(
                                                newIdentNode("typeof"),
                                                var_name
                                            ),
                                            assgn_right
                                        )
                                    )
                                )
                            )
                        )
                    )

                #perform / sample blocks. Also check names in the perform_build_names_table!
                else:
                    let 
                        names_table = newIdentNode("perform_build_names_table")
                        var_name_lit = newLit(var_name.strVal())

                    parsed_statement = nnkStmtList.newTree(
                        nnkWhenStmt.newTree(
                            nnkElifBranch.newTree(
                                nnkInfix.newTree(
                                    newIdentNode("and"),
                                    nnkCall.newTree(
                                        newIdentNode("not"),
                                        nnkPar.newTree(
                                            nnkInfix.newTree(
                                                newIdentNode("in"),
                                                var_name_lit,
                                                names_table
                                            )
                                        )
                                    ),
                                    nnkCall.newTree(
                                        newIdentNode("not"),
                                        nnkCall.newTree(
                                            newIdentNode("declaredInScope"),
                                            var_name
                                        ),
                                    )
                                ),
                                nnkStmtList.newTree(
                                    nnkVarSection.newTree(
                                        assgn_left
                                    )
                                )
                            ),
                            nnkElse.newTree(
                                nnkStmtList.newTree(
                                    nnkAsgn.newTree(
                                        var_name,
                                        nnkCall.newTree(
                                            nnkCall.newTree(
                                                newIdentNode("typeof"),
                                                var_name
                                            ),
                                            assgn_right
                                        )
                                    )
                                )
                            )
                        )
                    )

                    #error repr parsed_statement

            #out1 = ... (ONLY in perform / sample blocks)
            else:
                if is_perform_block:
                    parsed_statement = nnkAsgn.newTree(
                        var_name,
                        nnkCall.newTree(
                            nnkCall.newTree(
                                newIdentNode("typeof"),
                                var_name
                            ),
                            assgn_right
                        )
                    )

        #outs[i] in perform block (already been checked)
        elif is_outs_brackets:
            let audio_index_loop_bracket = nnkWhenStmt.newTree(
                nnkElifExpr.newTree(
                    nnkCall.newTree(
                        newIdentNode("declared"),
                        newIdentNode("audio_index_loop")
                    ),
                    nnkStmtList.newTree(
                        nnkBracketExpr.newTree(
                            nnkBracketExpr.newTree(
                                newIdentNode("outs_Nim"),
                                nnkCall.newTree(
                                    newIdentNode("int"),
                                    bracket_index
                                )  
                            ),
                            newIdentNode("audio_index_loop")
                        )
                    )
                ),
                nnkElseExpr.newTree(
                    nnkBracketExpr.newTree(
                        newIdentNode("outs_Nim"),
                        nnkCall.newTree(
                            newIdentNode("int"),
                            bracket_index
                        )
                    )
                )
            )
          
            parsed_statement = nnkStmtList.newTree(
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

        #All other normal assignments!
        else:
            parsed_statement = nnkStmtList.newTree(
                nnkAsgn.newTree(
                    var_name,
                    nnkCall.newTree(
                        nnkCall.newTree(
                            newIdentNode("typeof"),
                            var_name
                        ),
                        assgn_right
                    )
                )
            )

    return parsed_statement

#Parse the dot syntax: .
proc parse_untyped_dot(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    #print_parser_stage(statement, level)
    level += 1
    
    var parsed_statement = parser_untyped_loop(statement, level, is_constructor_block, is_perform_block, is_sample_block, is_def_block)

    return parsed_statement

#Parse the square bracket syntax: []
proc parse_untyped_brackets(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    #print_parser_stage(statement, level)
    level += 1

    #Parse the whole statement first
    var parsed_statement = parser_untyped_loop(statement, level, is_constructor_block, is_perform_block, is_sample_block, is_def_block) #keep parsing the entry of the bracket expr

    let 
        bracket_ident = parsed_statement[0]
        bracket_val   = parsed_statement[1]

    if bracket_ident.kind == nnkIdent:
        let bracket_ident_str = bracket_ident.strVal()

        #Look for ins[i]
        if bracket_ident_str == "ins":
            let audio_index_loop =  nnkWhenStmt.newTree(
                nnkElifExpr.newTree(
                    nnkCall.newTree(
                        newIdentNode("declared"),
                        newIdentNode("audio_index_loop")
                    ),
                    nnkStmtList.newTree(
                        newIdentNode("audio_index_loop")
                    )
                ),
                nnkElseExpr.newTree(
                    nnkStmtList.newTree(
                        newLit(0)
                    )
                )
            )
            
            parsed_statement = nnkCall.newTree(
                newIdentNode("get_dynamic_input"),
                newIdentNode("ins_Nim"),
                bracket_val,
                audio_index_loop
            )

    return parsed_statement


#Dispatcher logic
proc parser_untyped_dispatcher(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    let statement_kind = statement.kind
    
    var parsed_statement : NimNode

    if statement_kind   == nnkCall:
        parsed_statement = parse_untyped_call(statement, level, is_constructor_block, is_perform_block, is_sample_block, is_def_block)
    elif statement_kind == nnkCommand:
        parsed_statement = parse_untyped_command(statement, level, is_constructor_block, is_perform_block, is_sample_block, is_def_block)
    elif statement_kind == nnkAsgn:
        parsed_statement = parse_untyped_assign(statement, level, is_constructor_block, is_perform_block, is_sample_block, is_def_block)
    elif statement_kind == nnkDotExpr:
        parsed_statement = parse_untyped_dot(statement, level, is_constructor_block, is_perform_block, is_sample_block, is_def_block)
    elif statement_kind == nnkBracketExpr:
        parsed_statement = parse_untyped_brackets(statement, level, is_constructor_block, is_perform_block, is_sample_block, is_def_block)
    elif statement_kind == nnkExprEqExpr:
        parsed_statement = parse_untyped_expr_eq_expr(statement, level, is_constructor_block, is_perform_block, is_sample_block, is_def_block)
    elif statement_kind == nnkReturnStmt: #parse return statement just like calls, to detect constructors!
        parsed_statement = parse_untyped_call(statement, level, is_constructor_block, is_perform_block, is_sample_block, is_def_block)
    else:
        parsed_statement = parser_untyped_loop(statement, level, is_constructor_block, is_perform_block, is_sample_block, is_def_block)

    return parsed_statement
    
#Entry point: Parse entire block
proc parse_untyped_block_inner(code_block : NimNode, is_constructor_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false) : void {.compileTime.} =
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
        let parsed_statement = parser_untyped_dispatcher(statement, level, is_constructor_block, is_perform_block, is_sample_block, is_def_block)

        #echo repr statement

        #Replaced the parsed_statement
        if parsed_statement != nil:
            code_block[index] = parsed_statement

macro parse_block_untyped*(code_block_in : untyped, is_constructor_block_typed : typed = false, is_perform_block_typed : typed = false, is_sample_block_typed : typed = false, is_def_block_typed : bool = false, bits_32_or_64_typed : typed = false) : untyped =
    var 
        #used to wrap the whole code_block in a block: statement to create a closed environment to be semantically checked, and not pollute outer scope with symbols.
        final_block = nnkBlockStmt.newTree(
            newEmptyNode()
        )

        code_block  = code_block_in

    let 
        is_constructor_block = is_constructor_block_typed.boolVal()
        is_perform_block = is_perform_block_typed.boolVal()
        is_sample_block = is_sample_block_typed.boolVal()
        is_def_block = is_def_block_typed.boolVal()
        bits_32_or_64 = bits_32_or_64_typed.boolVal()

    #Sample block without perform
    if is_sample_block:
        code_block = parse_sample_block(code_block)

    #Standard perform block (is_sample_block is false here too)
    elif is_perform_block:
        var found_sample_block = false
        
        #Perhaps this loop can easily be moved in the parse_block function altogether
        for index, statement in code_block.pairs():
            if statement.kind == nnkCall:
                let 
                    var_ident = statement[0]
                    var_misc  = statement[1]
                
                #Look for the sample block inside of perform
                if var_ident.strVal == "sample":
                    let sample_block = var_misc

                    #Replace the sample: block with the new parsed one.
                    code_block[index] = parse_sample_block(sample_block)

                    found_sample_block = true

                    break
            
        #couldn't find sample block IN perform block
        if not found_sample_block:
            error "'perform': no 'sample' block provided, or not at top level."
        
    
    #Remove new statement from the block before all syntactic analysis.
    #This is needed for this to work:
    #build:
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

    #if is_perform_block:
    #    error repr code_block

    #Begin parsing
    parse_untyped_block_inner(code_block, is_constructor_block, is_perform_block, is_sample_block, is_def_block)

    #error repr code_block

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

    #echo repr final_block

    #Run the actual macro to subsitute structs with let statements
    return quote do:
        #Need to run through an evaluation in order to get the typed information of the block:
        parse_block_typed(`final_block`, `build_statement`, `is_constructor_block_typed`, `is_perform_block_typed`)

# ============================== #
# Stage 2: Typed code generation #
# ============================== #

#Forward declaration
proc parser_typed_dispatcher(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false) : NimNode {.compileTime.}

#Loop around statement and trigger dispatch, performing code substitution
proc parser_typed_loop(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false) : NimNode {.compileTime.} =
    var parsed_statement = statement
    if statement.len > 0:
        for index, statement_inner in statement.pairs():
            #Substitute old content with the parsed one
            parsed_statement[index] = parser_typed_dispatcher(statement_inner, level, is_constructor_block, is_perform_block)
    return parsed_statement

#Parse the call syntax: function(arg)
proc parse_typed_call(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false) : NimNode {.compileTime.} =
    #print_parse_typed_stage(statement, level)
    level += 1

    var parsed_statement = parser_typed_loop(statement, level, is_perform_block)

    let function_call = parsed_statement[0]

    if function_call.kind == nnkSym or function_call.kind == nnkIdent:
        
        let function_name = function_call.strVal()

        #echo function_name

        #Fix Data/Buffer access: from [] = (delay_data, phase, write_value) to delay_data[phase] = write_value
        if function_name == "[]=":                
            var new_array_assignment : NimNode

            #1 channel
            if parsed_statement[1].kind == nnkDotExpr:
                new_array_assignment = nnkAsgn.newTree(
                    nnkBracketExpr.newTree(
                        parsed_statement[1],
                        parsed_statement[2]
                    ),
                    parsed_statement[3]
                )

            #Multi channel
            else:
                let bracket_expr = nnkBracketExpr.newTree(parsed_statement[1])
                
                #Extract indexes
                for channel_index in 2..parsed_statement.len-2:
                    bracket_expr.add(parsed_statement[channel_index])

                new_array_assignment = nnkAsgn.newTree(
                    bracket_expr,
                    parsed_statement.last()
                )
            
            if new_array_assignment != nil:
                parsed_statement = new_array_assignment

        #If a struct_new_inner call without generics (and the struct has generics), use floats! (Otherwise it will default to ints due to the struct_new template)
        elif function_name == "struct_new_inner":
            var struct_type = parsed_statement[1]

            #If struct_type is a bracketexpr, it means it already has generics mapping laid out. no need to run these.
            if struct_type.kind == nnkSym or struct_type.kind == nnkIdent:
                #Data has been parsed correctly already
                if struct_type.strVal() != "Data":
                    let 
                        struct_impl = struct_type.getImpl()
                        generic_params = struct_impl[1]

                    if generic_params.kind == nnkGenericParams:
                        var 
                            new_struct_new_inner = nnkCall.newTree(
                                newIdentNode("struct_new_inner"),
                            )

                            new_struct_expl_type = nnkBracketExpr.newTree(
                                struct_type
                            )
                        
                        #instantiate float for all generic params
                        for generic_param in generic_params:
                            new_struct_expl_type.add(
                                newIdentNode("float")
                            )

                        new_struct_new_inner.add(new_struct_expl_type)

                        #Re-attach all the args
                        for index,arg in parsed_statement.pairs():
                            if index <= 1:
                                continue
                            new_struct_new_inner.add(arg)

                        #Add to code_block
                        parsed_statement = new_struct_new_inner

        #Check type of all arguments for other function calls (not array access related) 
        #Ignore function ending in _min_max (the one used for input min/max conditional) OR get_dynamic_input
        #THIS IS NOT SAFE! min_max could be assigned by user to another def
        elif parsed_statement.len > 1 and not(function_name.endsWith("_min_max")) and not(function_name == "get_dynamic_input"):
            for i, arg in parsed_statement.pairs():
                #ignore i == 0 (the function_name)
                if i == 0:
                    continue

                #Only check if actually it's possible to get the type (it's a sym). Something like safediv would be ident
                if arg.kind == nnkSym:
                    let arg_type = arg.getTypeInst().getTypeImpl()

                    #Check validity of each argument to function
                    checkValidType(arg_type, $i, is_proc_call=true, proc_name=function_name)

    return parsed_statement


#Parse the var section
proc parse_typed_var_section(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false) : NimNode {.compileTime.} =
    #print_parse_typed_stage(statement, level)
    level += 1

    var parsed_statement = parser_typed_loop(statement, level, is_perform_block)

    let 
        var_symbol = parsed_statement[0][0]
        var_type   = var_symbol.getTypeInst().getTypeImpl()
        var_name   = var_symbol.strVal()

    if var_name in non_valid_variable_names:
        error("'" & $var_name & "' is an invalid variable name: it's the name of an in-built type.")

    #Check if it's a valid type
    checkValidType(var_type, var_name)

    #Look for consts: capital letters.
    if var_name.isStrUpperAscii(true):
        let old_statement_body = parsed_statement[0]

        #Create new let statement
        let new_let_statement = nnkLetSection.newTree(
            old_statement_body
        )

        #Replace the entry in the untyped block, which has yet to be semantically evaluated.
        parsed_statement = new_let_statement

    #Look for ptr types, structs
    if var_type.kind == nnkPtrTy:
        #Found a struct!
        if var_type.isStruct():
            let old_statement_body = parsed_statement[0]

            #Detect if it's a non-initialized struct variable (e.g "data Data[float]")
            if old_statement_body.len == 3:
                if old_statement_body[2].kind == nnkEmpty:
                    let error_var_name = old_statement_body[0]
                    error("'" & $error_var_name & "': structs must be instantiated on declaration.")
            
            #If trying to assign a ptr type to any variable.. this won't probably be caught as it's been already parsed from untyped to typed...
            #if is_perform_block:
            #    error("`" & $var_name & "`: cannot declare new structs in the `perform` or `sample` blocks.")

            #All good, create new let statement
            let new_let_statement = nnkLetSection.newTree(
                old_statement_body
            )

            #Replace the entry in the untyped block, which has yet to be semantically evaluated.
            parsed_statement = new_let_statement

    return parsed_statement

proc parse_typed_infix(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false) : NimNode {.compileTime.} =
    level += 1

    var parsed_statement = parser_typed_loop(statement, level, is_perform_block)

    assert parsed_statement.len == 3

    let 
        infix_symbol = parsed_statement[0]
        infix_str    = infix_symbol.strVal()

    if infix_str == "/" or infix_str == "div":
        parsed_statement = nnkCall.newTree(
            newIdentNode("safediv"),
            parsed_statement[1],
            parsed_statement[2]
        )

    elif infix_str == "%" or infix_str == "mod":
        parsed_statement = nnkCall.newTree(
            newIdentNode("safemod"),
            parsed_statement[1],
            parsed_statement[2]
        )

    return parsed_statement

proc parse_typed_assgn(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false) : NimNode {.compileTime.} =
    level += 1

    var 
        parsed_statement = parser_typed_loop(statement, level, is_perform_block)
        assgn_right = parsed_statement[0]

    #Ignore 'result' (which is used in return stmt)
    if assgn_right.kind == nnkSym:
        if assgn_right.strVal() == "result":
            return parsed_statement

    if isStruct(assgn_right):
        if assgn_right.kind == nnkDotExpr:
            error("'" & assgn_right.repr & "': trying to re-assign an already allocated struct field.")
        else:
            error("'" & assgn_right.repr & "': trying to re-assign an already allocated struct.")

    return parsed_statement

#Substitute the entry name with data[i], and the let section with assignment
proc for_loop_substitute(code_block : NimNode, entry : NimNode, substitution : NimNode) : void =
    if code_block.len > 0:
        for index, statement in code_block:
            if statement.kind == nnkLetSection or statement.kind == nnkVarSection:
                let 
                    ident_defs = statement[0]
                    let_variable = ident_defs[0]
                    asgnment = ident_defs[2] #1 is empty node
                if let_variable.kind == nnkSym or let_variable.kind == nnkIdent:
                    if let_variable.strVal() == entry.strVal():
                        let asgn_stmt = nnkAsgn.newTree(
                            substitution,
                            asgnment
                        )
                        code_block[index] = asgn_stmt
            if statement.kind == nnkSym or statement.kind == nnkIdent:
                if statement.strVal() == entry.strVal():
                    code_block[index] = substitution
            for_loop_substitute(statement, entry, substitution)

#This parses for loops.
#It's used to do so:
#a = Data[Something](10)
#for entry in a:
#   entry = Something()
#OR
#for i, entry in a:
#   entry = Something(i)
proc parse_typed_for(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false) : NimNode {.compileTime.} =
    level += 1

    var parsed_statement = statement
    
    parsed_statement = parser_typed_loop(statement, level, is_constructor_block, is_perform_block)
    
    var 
        index1 = parsed_statement[0]
        index2 = parsed_statement[1]

    #for i, entry in data:
    if index2.kind == nnkSym:
        if parsed_statement[2].kind != nnkInfix:
            let 
                index = index1
                entry = index2
                data_name = parsed_statement[2][1]
                bracket_expr = nnkBracketExpr.newTree(
                    data_name,
                    index
                )

            let check_data = data_name.getTypeInst()
            var is_data = false
            if check_data.kind == nnkBracketExpr:
                if check_data[0].kind == nnkSym:
                    if check_data[0].strVal() == "Data":
                        is_data = true
            elif check_data.kind == nnkPtrTy:
                if check_data[0].kind == nnkBracketExpr:
                    if check_data[0][0].kind == nnkSym:
                        if check_data[0][0].strVal() == "Data_struct_inner":
                            is_data = true

            if is_data:
                var for_loop_body = parsed_statement[3]
                if for_loop_body.kind == nnkLetSection or for_loop_body.kind == nnkVarSection:
                    let 
                        ident_defs = for_loop_body[0]
                        let_variable = ident_defs[0]
                        asgnment = ident_defs[2] #1 is empty node
                    if let_variable.kind == nnkSym or let_variable.kind == nnkIdent:
                        if let_variable.strVal() == entry.strVal():
                            let asgn_stmt = nnkAsgn.newTree(
                                bracket_expr,
                                asgnment
                            )
                            for_loop_body = asgn_stmt

                for_loop_substitute(for_loop_body, entry, bracket_expr)

                parsed_statement[3] = for_loop_body
        
    #for entry in data:
    else:
        if parsed_statement[1].kind != nnkInfix:
            let 
                entry = index1
                data_name = parsed_statement[1][1]
                index = genSym(ident="data_index") #unique symbol generation
                bracket_expr = nnkBracketExpr.newTree(
                    data_name,
                    index
                )
            
            let check_data = data_name.getTypeInst()

            var is_data = false
            if check_data.kind == nnkBracketExpr:
                if check_data[0].kind == nnkSym:
                    if check_data[0].strVal() == "Data":
                        is_data = true
            elif check_data.kind == nnkPtrTy:
                if check_data[0].kind == nnkBracketExpr:
                    if check_data[0][0].kind == nnkSym:
                        if check_data[0][0].strVal() == "Data_struct_inner":
                            is_data = true
            
            if is_data:
                var for_loop_body = parsed_statement[2]
                if for_loop_body.kind == nnkLetSection or for_loop_body.kind == nnkVarSection:
                    let 
                        ident_defs = for_loop_body[0]
                        let_variable = ident_defs[0]
                        asgnment = ident_defs[2] #1 is empty node
                    if let_variable.kind == nnkSym or let_variable.kind == nnkIdent:
                        if let_variable.strVal() == entry.strVal():
                            let asgn_stmt = nnkAsgn.newTree(
                                bracket_expr,
                                asgnment
                            )
                            for_loop_body = asgn_stmt

                for_loop_substitute(for_loop_body, entry, bracket_expr)

                parsed_statement = nnkForStmt.newTree(
                    index,
                    nnkInfix.newTree(
                        newIdentNode(".."),
                        newLit(0),
                        nnkInfix.newTree(
                            newIdentNode("-"),
                            nnkCall.newTree(
                                newIdentNode("len"),
                                data_name
                            ),
                            newLit(1)
                        )
                    ),
                    for_loop_body
                )

        #error astGenRepr parsed_statement

    #echo repr parsed_statement

    return parsed_statement

#Dispatcher logic
proc parser_typed_dispatcher(statement : NimNode, level : var int, is_constructor_block : bool = false, is_perform_block : bool = false) : NimNode {.compileTime.} =
    let statement_kind = statement.kind
    
    var parsed_statement : NimNode

    #level += 1

    if statement_kind   == nnkCall:
        parsed_statement = parse_typed_call(statement, level, is_constructor_block, is_perform_block)
    elif statement_kind == nnkVarSection:
        parsed_statement = parse_typed_var_section(statement, level, is_constructor_block, is_perform_block)
    elif statement_kind == nnkInfix:
        parsed_statement = parse_typed_infix(statement, level, is_constructor_block, is_perform_block)
    elif statement_kind == nnkAsgn:
        parsed_statement = parse_typed_assgn(statement, level, is_constructor_block, is_perform_block)
    elif statement_kind == nnkForStmt:
        parsed_statement = parse_typed_for(statement, level, is_constructor_block, is_perform_block)
    else:
        parsed_statement = parser_typed_loop(statement, level, is_constructor_block, is_perform_block)

    return parsed_statement
    
#Entry point: Parse entire block
proc parse_typed_block_inner(code_block : NimNode, is_constructor_block : bool = false, is_perform_block : bool = false) : void {.compileTime.} =
    for index, statement in code_block.pairs():
        #Initial level, 0
        var level : int = 0
        let parsed_statement = parser_typed_dispatcher(statement, level, is_constructor_block, is_perform_block)

        #Replaced the parsed_statement
        if parsed_statement != nil:
            code_block[index] = parsed_statement


#This allows to check for types of the variables and look for structs to declare them as let instead of var
macro parse_block_typed*(typed_code_block : typed, build_statement : untyped, is_constructor_block_typed : typed = false, is_perform_block_typed : typed = false) : untyped =
    #Extract the body of the block: [0] is an emptynode
    var inner_block = typed_code_block[1].copy()

    #And also wrap it in a StmtList (if it wasn't a StmtList already)
    if inner_block.kind != nnkStmtList:
        inner_block = nnkStmtList.newTree(inner_block)
    
    let 
        is_constructor_block = is_constructor_block_typed.strVal() == "true"
        is_perform_block = is_perform_block_typed.strVal() == "true"

    parse_typed_block_inner(inner_block, is_constructor_block, is_perform_block)

    #Will return an untyped code block!
    result = typedToUntyped(inner_block)

    #error repr result

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

    #error repr result 
