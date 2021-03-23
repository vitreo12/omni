# MIT License
# 
# Copyright (c) 2020-2021 Francesco Cameli
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

import macros, strutils
import omni_loop, omni_invalid, omni_type_checker, omni_macros_utilities
from omni_io import omni_ins_names_list, omni_params_names_list, omni_buffers_names_list

#Used to check highest in / out
var 
    omni_highest_in {.compileTime.}  = 0
    omni_highest_out {.compileTime.} = 0

proc check_highest_in(ident : NimNode) : void {.compileTime.} =
    let 
        var_name_str = ident.strVal()
        var_name_str_len = var_name_str.len

    var in_val = 0
    #in1.. / in10.. / in100..
    if var_name_str_len == 3:
        let in_num_char = var_name_str[2]
        if in_num_char.isDigit:
            in_val = parseInt($in_num_char)
    elif var_name_str_len == 4:
        let 
            in_num_char_one = var_name_str[2]
            in_num_char_two = var_name_str[3]
        if in_num_char_one.isDigit and in_num_char_two.isDigit:
            in_val = parseInt($var_name_str[2..3])
    elif var_name_str_len == 5:
        let 
            in_num_char_one = var_name_str[2]
            in_num_char_two = var_name_str[3]
            in_num_char_three = var_name_str[4]
        if in_num_char_one.isDigit and in_num_char_two.isDigit and in_num_char_three.isDigit:
            in_val = parseInt($var_name_str[2..4])
    
    if in_val > omni_highest_in:
        omni_highest_in = in_val

proc check_highest_out(val : int) : void {.compileTime.} =
    if val > omni_highest_out:
        omni_highest_out = val

#Types that will be converted to float when in tuples (if not explicitly set)
let omni_tuple_convert_types {.compileTime.} = [
    "cfloat", "cdouble", "float32", "float64",
    "cint", "clong", "int", "int32", "int64"
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
proc omni_parse_sample_block(sample_block : NimNode) : NimNode {.compileTime.} =
    return nnkStmtList.newTree(
        nnkCall.newTree(
            newIdentNode("omni_generate_inputs_templates"),
            newIdentNode("omni_inputs"),
            newLit(1),
            newLit(0)
        ),

        nnkCall.newTree(
            newIdentNode("omni_generate_outputs_templates"),
            newIdentNode("omni_outputs")
        ),

        nnkForStmt.newTree(
            newIdentNode("omni_audio_index"),
            nnkInfix.newTree(
                newIdentNode("..<"),
                newLit(0),
                newIdentNode("bufsize")
            ),
            nnkStmtList.newTree(
                #Declare ins unpacking as variable names for the sample block
                nnkCall.newTree(
                    newIdentNode("omni_unpack_ins_perform"),
                    newIdentNode("omni_inputs_names_const")
                ),
                
                #Actually append the sample block
                sample_block
            ) 
        ),

        nnkLetSection.newTree(
            nnkIdentDefs.newTree(
                newIdentNode("omni_audio_index"),
                newEmptyNode(),
                newLit(0)
            )
        )
    )

#Find struct calls in a nnkCall and replace them with .new calls.
#To do so, pass a function call here. What is prduced is a when statement that checks
#if the function name + "_omni_struct" is declared, meaning it's a struct constructor the user is trying to call.
#This also covers the Phasor.new() syntax, as the name of the class' only callable function is struct_new anyway.
#e.g.
# Phasor(0.0)  -> when declared(Phasor_omni_struct): Phasor.struct_new(0.0) else: Phasor(0.0)
# myFunc(0.0)  -> when declared(myFunc_omni_struct): myFunc.struct_new(0.0) else: myFunc(0.0)
# Phasor.new() -> when declared(Phasor_omni_struct): Phasor.struct_new() else: Phasor.new()

# ALSO GENERICS: (Data has a different behaviour)
# Phasor[float]() -> when declared(Phasor_omni_struct) : Phasor[float].struct_new() else: Phasor[float]()
# Data[int](10) -> when declared(Data_omni_struct) : Data.struct_new(10, dataType=int) else: Data[int](10)
proc omni_find_struct_constructor_call*(statement : NimNode) : NimNode {.compileTime.} =
    if statement.kind != nnkCall:
        return statement

    var parsed_statement = statement

    var 
        proc_call_ident = parsed_statement[0]
        proc_call_ident_kind = proc_call_ident.kind

    #Dot expr would be Data.new() or something.perform() and Data[float].new() etc.
    if proc_call_ident_kind == nnkDotExpr or proc_call_ident_kind == nnkBracketExpr:
        proc_call_ident = proc_call_ident[0]
        proc_call_ident_kind = proc_call_ident.kind
        
        #This happens for Data[float].new
        if proc_call_ident_kind == nnkBracketExpr:
            proc_call_ident = proc_call_ident[0]
            proc_call_ident_kind = proc_call_ident.kind
    
    if proc_call_ident_kind != nnkIdent and proc_call_ident_kind != nnkSym:
        return statement

    var proc_call_ident_str = proc_call_ident.strVal()

    #Ignore the calls that belong to sample block
    if proc_call_ident_str == "omni_generate_inputs_templates" or proc_call_ident_str == "omni_generate_outputs_templates" or proc_call_ident_str == "omni_unpack_ins_perform":
        return statement

    var 
        omni_struct_ptr_name = newIdentNode(proc_call_ident_str & "_omni_struct_ptr")
        proc_call_ident_omni_struct_new = newIdentNode(proc_call_ident_str & "_omni_struct_new")

    var proc_new_call =  nnkCall.newTree(
        proc_call_ident_omni_struct_new,
    )

    var explicit_generics = false

    for index, arg in statement:
        var arg_temp = arg
        
        if index == 0:
            #This happens for Data[float].new() or Phasor[float].new()
            if arg_temp.kind == nnkDotExpr:
                arg_temp = arg_temp[0]

            #Look for Data[int](10) OR Phasor[int]() syntax
            if arg_temp.kind == nnkBracketExpr:
                omni_struct_ptr_name = arg_temp
                explicit_generics = true

            #Continue in any case: the ident name it's already been added
            continue
        
        #Find other constructors in the args of the call, including the one expressed like: arg=value (nnkExprEqExpr)
        if arg_temp.kind == nnkCall:
            arg_temp = omni_find_struct_constructor_call(arg_temp)
        
        elif arg_temp.kind == nnkExprEqExpr:
            arg_temp[1] = omni_find_struct_constructor_call(arg_temp[1])

        #Add the new parsed struct call
        proc_new_call.add(arg_temp)
    
    #Add the named generics!
    if explicit_generics:
        for i, generic_val in omni_struct_ptr_name:
            if i == 0:
                continue

            let 
                new_G_generic_ident = newIdentNode("G" & $i)
                generic_eq_expr = nnkExprEqExpr.newTree(
                    new_G_generic_ident,
                    generic_val
                )

            #Add generics to constructor
            proc_new_call.add(
                generic_eq_expr
            )

            #Add generics to def call: someFunc[int]() -> someFunc(G1 = int)
            if parsed_statement[0].kind == nnkBracketExpr:
                parsed_statement[0] = newIdentNode(
                    parsed_statement[0][0].strVal()
                )

                parsed_statement.add(
                    generic_eq_expr
                )
            else:
                parsed_statement.add(
                    generic_eq_expr
                )

    #Now prepend samplerate, bufsize, omni_struct_type, omni_auto_mem and omni_call_type with named access!
    proc_new_call.add(
        nnkExprEqExpr.newTree(
            newIdentNode("samplerate"),
            newIdentNode("samplerate")
        ),

        nnkExprEqExpr.newTree(
            newIdentNode("bufsize"),
            newIdentNode("bufsize")
        ),

        nnkExprEqExpr.newTree(
            newIdentNode("omni_struct_type"),
            omni_struct_ptr_name
        ),

        nnkExprEqExpr.newTree(
            newIdentNode("omni_auto_mem"),
            newIdentNode("omni_auto_mem")
        ),
        
        nnkExprEqExpr.newTree(
            newIdentNode("omni_call_type"),
            newIdentNode("omni_call_type")
        )
    )

    #Can't create a Buffer explicitly
    if proc_call_ident_str == "Buffer":
        error("'" & (repr(statement)) & "': Buffers can't be created explicitly. Use the 'buffers' interface instead.", statement)

    #This happens in normal code
    let when_statement_struct_new = nnkWhenStmt.newTree(
        nnkElifExpr.newTree(
            nnkCall.newTree(
                newIdentNode("declared"),
                proc_call_ident_omni_struct_new
            ),
            nnkStmtList.newTree(
                proc_new_call
            )
        ),
        nnkElseExpr.newTree(
            nnkStmtList.newTree(
                parsed_statement
            )
        )
    )

    result = when_statement_struct_new

    # error repr result

# ================================ #
# Stage 1: Untyped code generation #
# ================================ #

#Forward declaration
proc omni_parser_untyped_dispatcher(statement : NimNode, level : var int, declared_vars : var seq[string], is_init_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false, extra_data : NimNode) : NimNode {.compileTime.}

#Utility print
proc omni_print_parser_stage(statement : NimNode, level : int) : void {.compileTime.} =
    var val_spaces : string
    for i in 0..level-1:
        val_spaces.add(" ")
    if level == 0:
        echo ""
    echo $val_spaces & $level & ": " & $statement.kind & " -> " & repr(statement)

#Loop around statement and trigger dispatch, performing code substitution
proc omni_parser_untyped_loop(statement : NimNode, level : var int, declared_vars : var seq[string], is_init_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false, extra_data : NimNode) : NimNode {.compileTime.} =
    var parsed_statement = statement
    if statement.len > 0:
        for index, statement_inner in statement:
            #Substitute old content with the parsed one
            parsed_statement[index] = omni_parser_untyped_dispatcher(statement_inner, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)
    return parsed_statement

#Parse the call syntax: function(arg)
proc omni_parse_untyped_call(statement : NimNode, level : var int, declared_vars : var seq[string], is_init_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false, extra_data : NimNode) : NimNode {.compileTime.} =
    #Parse the call
    var parsed_statement = omni_parser_untyped_loop(statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)

    let 
        call_name = parsed_statement[0]
        call_name_kind = call_name.kind

    if call_name.kind == nnkIdent:
        let call_name_str = call_name.strVal()

        #loop(4) / loop(i, 4)
        if call_name_str == "loop":
            parsed_statement = omni_loop_inner(parsed_statement.copy())
            return parsed_statement
        
        #Detect out of position "build" calls in "init"
        if is_init_block and call_name_str == "build":
            error("init: the 'build' call, if used, must only be one and at the last position of the 'init' block.", statement)
        
    #Something weird happened with Data[Something]() in a def.. It returned a call to a
    #nnkOpenSymChoice with symbols.. Re-interpret it and re-run parser (NEEDS MORE TESTING!)
    if call_name_kind == nnkCall:
        if call_name[0].kind == nnkOpenSymChoice:
            var new_statement = typed_to_untyped(parsed_statement)
            parsed_statement = omni_parser_untyped_loop(new_statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)
    
    #Happens on []= assignments ... 
    #make sure to typeof the access 
    #this is needed for tuples, not Data and Buffer (these extra typeofs are removed in typed section)
    elif call_name_kind == nnkOpenSymChoice:
        if call_name[0].strVal() == "[]=":
            if parsed_statement.len == 4:
                let 
                    array_var   = parsed_statement[1]
                    array_index = parsed_statement[2]
                    asgn_val   = parsed_statement[3]

                #Replace the val assignment with typeof the accessed array bit
                parsed_statement[3] = nnkCall.newTree(
                    nnkCall.newTree(
                        newIdentNode("typeof"),
                        nnkCall.newTree(
                            newIdentNode("[]"),
                            array_var,
                            array_index
                        )
                    ),
                    asgn_val
                )

                #error repr parsed_statement
        
        #error repr call_name
        
    #Detect constructor calls
    parsed_statement = omni_find_struct_constructor_call(parsed_statement)

    if is_def_block and statement.kind == nnkReturnStmt:
        var return_val = parsed_statement[0]

        #Retrieve return type of def from extra_data
        var 
            return_type = extra_data
            return_type_kind = return_type.kind

        #Convert value if explicitly expressed by user. 
        #This would just work for number types anyway.
        if return_type_kind == nnkIdent or return_type_kind == nnkSym:
            if return_type.strVal() != "auto":
                return_val = nnkCall.newTree(
                    return_type,
                    return_val
                )

        #Convert "return" to "omni_temp_result... ="
        #This is needed to avoid type checking weirdness in the def block!
        parsed_statement = nnkLetSection.newTree(
            nnkIdentDefs.newTree(
                genSym(ident="omni_temp_result"),
                newEmptyNode(),
                return_val
            )
        )

    return parsed_statement

#Parse the eq expr syntax, Test(data=Data())
proc omni_parse_untyped_expr_eq_expr(statement : NimNode, level : var int, declared_vars : var seq[string], is_init_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false, extra_data : NimNode) : NimNode {.compileTime.} =
    var parsed_statement = omni_parser_untyped_loop(statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)
    return parsed_statement

#Parse the command syntax... Disabled it... Variables must ALWAYS been initialized
proc omni_parse_untyped_command(statement : NimNode, level : var int, declared_vars : var seq[string], is_init_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false, extra_data : NimNode) : NimNode {.compileTime.} =
    var 
        parsed_statement : NimNode
        new_stmt = false
        loop_stmt = false
        command_name = statement[0]
        command_name_kind = command_name.kind

    #Detect out of position "build" calls in "init"
    if is_init_block:
        if command_name_kind == nnkIdent:
            if command_name.strVal() == "build":
                error("init: the 'build' call, if used, must only be one and at the last position of the 'init' block.", statement)

    #ident statements: "loop", "new"
    if command_name.kind == nnkIdent:
        let command_name_str = command_name.strVal()
        
        if command_name_str == "new":
            command_name = statement[1]
            command_name_kind = command_name.kind
            new_stmt = true

            #new Data(1).. Just use the nnkCall
            if command_name_kind == nnkCall:
                parsed_statement = command_name.copy()

            #new Data 1 ... Not so sure if I wanna support this syntax TBH
            elif command_name_kind == nnkCommand:
                parsed_statement = nnkCall.newTree(
                    command_name[0]
                )

                #Put all the stuff back in, using command name (not statement!)
                for i, entry in command_name:
                    if i == 0: continue #skip func name
                    parsed_statement.add(entry)
                
            #new Data / new Data[float]
            elif command_name_kind == nnkIdent or command_name_kind == nnkBracketExpr:
                parsed_statement = nnkCall.newTree(
                    command_name
                )
            
            else:
                error("'" & $repr(statement) & "': Invalid 'new' syntax.", statement)
        
        #loop 4 / loop i 4
        elif command_name_str == "loop":
            loop_stmt = true
            parsed_statement = omni_loop_inner(statement.copy())
            
    #This is the normal case for all commands: just turn them to nnkCalls.
    if not new_stmt and not loop_stmt:
        parsed_statement = nnkCall.newTree(
            command_name
        )

        #Put all the stuff back in
        for i, entry in statement:
            if i == 0: continue #skip func name
            parsed_statement.add(entry)

    #Wrap in stmt list for parsing to work (the omni_parser_untyped_loop works with looping around children)
    parsed_statement = nnkStmtList.newTree(
        parsed_statement
    )

    #Run parsing on the nnkCall :)
    parsed_statement = omni_parser_untyped_loop(parsed_statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)

    return parsed_statement

#a (int, (int, float)) = (1, (1, 1)) -> (int(1), (int(1), float(1)))
proc omni_tuple_untyped_assign(tuple_type : NimNode, tuple_val : NimNode) : void {.compileTime.} = 
    #Loop over all tuple_type
    for i, inner_tuple_type in tuple_type:
        if tuple_val.len <= i:
            continue

        var inner_tuple_val = tuple_val[i]

        #tuple of tuples: run conversion only if both tuple_val and tuple_type are tuples:
        #check tuple_val first, for mismatches!
        if inner_tuple_val.kind == nnkPar:
            if inner_tuple_type.kind == nnkPar:
                omni_tuple_untyped_assign(inner_tuple_type, inner_tuple_val)
        
        #individual value, run conversion!
        else:
            #Extra check... This should exclude function calls with pars too
            let inner_tuple_type_kind = inner_tuple_type.kind
            if inner_tuple_type_kind == nnkSym or inner_tuple_type_kind == nnkIdent:
                tuple_val[i] = nnkCall.newTree(
                    inner_tuple_type,
                    inner_tuple_val
                )

#Parse the assign syntax: a float = 10 OR a = 10
proc omni_parse_untyped_assign(statement : NimNode, level : var int, declared_vars : var seq[string], is_init_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false, extra_data : NimNode) : NimNode {.compileTime.} =
    #Don't keep the parsed things before the = (so that commands will only be parsed in the asgn_right)
    var parsed_statement = statement.copy() 
    parsed_statement = omni_parser_untyped_loop(parsed_statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)
        
    var
        asgn_left : NimNode
        asgn_right : NimNode
        is_command_or_ident = false
        is_outs_brackets = false
        bracket_ident : NimNode
        bracket_index : NimNode

    if parsed_statement.len > 1:
        #Don't keep the parsed things before the = (so that commands will only be parsed in the asgn_right)
        parsed_statement[0] = statement[0] #reput previous asgn_left. Needed to do statement.copy() for this reason: need the old one

        asgn_left  = parsed_statement[0]
        asgn_right = parsed_statement[1]

        let asgn_left_kind = asgn_left.kind
        
        #Tryin to declare a variable named "tuple" or "type"
        if asgn_left_kind == nnkTupleClassTy:
            error("Can't declare a variable named 'tuple'. It's a keyword for internal use.", asgn_left)
        elif asgn_left_kind == nnkTypeClassTy:
            error("Can't declare a variable named 'type'. It's a keyword for internal use.", asgn_left)
        
        #Command assignment: a float = 0.0
        if asgn_left_kind == nnkCommand:
            if asgn_left.len != 2:
                error("Invalid variable type declaration.", asgn_left)

            let 
                var_name = asgn_left[0]
                var_type = asgn_left[1]

            var new_asgn_right : NimNode

            #Detect tuple assignment, gotta convert every single entry, or the nim untyped parser won't be happy
            #a (int, (int, float)) = (1, (1, 1)) -> (int(1), (int(1), float(1)))
            #This however won't work with function returns, as tuples can't be casted in group:
            #a (int, (int, float)) = (1, someFunc()) -> if someFunc doesn't return (int, float), it's an error :)
            if var_type.kind == nnkPar:
                #new_asgn_right is modified in place in omni_tuple_untyped_assign
                new_asgn_right = asgn_right
                omni_tuple_untyped_assign(var_type, new_asgn_right)

                #error repr new_asgn_right
            
            #a int = 123.214 -> a : int = int(123.324)...
            #Is this REALLY necessary? Shouldn't the user be careful on this by himself, without
            #adding this additional check?
            else:
                new_asgn_right = nnkCall.newTree(
                    var_type,
                    asgn_right
                )

                #No casting:
                #new_asgn_right = asgn_right

            #error repr new_asgn_right

            #Build final ident defs, using the newly converted new_asgn_right
            asgn_left = nnkIdentDefs.newTree(
                var_name,
                var_type,
                new_asgn_right
            )

            is_command_or_ident = true
        
        #All other cases: normal ident: a = 10, bracket: a[i] = 10, dot: a.b = 10
        else:
            #Normal assignment: a = 0.0
            if asgn_left_kind == nnkIdent:
                is_command_or_ident = true
            
            #Look for outs[i] in perform block
            elif is_perform_block and asgn_left_kind == nnkBracketExpr:
                bracket_ident = asgn_left[0]
                bracket_index = asgn_left[1]
                if bracket_ident.kind == nnkIdent:
                    if bracket_ident.strVal() == "outs":
                        is_outs_brackets = true

            asgn_left = nnkIdentDefs.newTree(
                asgn_left,
                newEmptyNode(),
                asgn_right
            )

    if asgn_left != nil:
        let var_name     = asgn_left[0]
 
        var 
            var_name_str : string
            var_already_declared = false

        if var_name.kind == nnkIdent:
            var_name_str = var_name.strVal()

        #If already in the seq, set boolean to true. else, add it,
        #This, together with parse_untyped_elif_else_for_while, will also take care of inner scopes!
        if var_name_str in declared_vars:
            var_already_declared = true
        else:
            declared_vars.add(var_name_str)
        
        #look for out1.. etc to perform typeof
        var is_out_variable = false

        if var_name_str.startsWith("out"):
            let var_name_str_len = var_name_str.len
            #out1.. / out10.. / out 100
            if var_name_str_len == 4:
                let out_num = var_name_str[3]
                if out_num.isDigit:
                    #Only check highest_out if in perform / sample blocks
                    if is_perform_block or is_sample_block:
                        check_highest_out(parseInt($out_num))
                    is_out_variable = true
            elif var_name_str_len == 5:
                let 
                    out_num_one = var_name_str[3]
                    out_num_two = var_name_str[4]
                if out_num_one.isDigit and out_num_two.isDigit:
                    #Only check highest_out if in perform / sample blocks
                    if is_perform_block or is_sample_block:
                        check_highest_out(parseInt($var_name_str[3..4]))
                    is_out_variable = true
            elif var_name_str_len == 6:
                let 
                    out_num_one = var_name_str[3]
                    out_num_two = var_name_str[4]
                    out_num_three = var_name_str[5]
                if out_num_one.isDigit and out_num_two.isDigit and out_num_three.isDigit:
                    #Only check highest_out if in perform / sample blocks
                    if is_perform_block or is_sample_block:
                        check_highest_out(parseInt($var_name_str[3..5]))
                    is_out_variable = true
        
        #can't define a variable as in1, in2, etc...
        elif var_name_str.startsWith("in"):
            let var_name_str_len = var_name_str.len
            #in1.. / in10.. / in100
            if var_name_str_len == 3:
                if var_name_str[2].isDigit:
                    error("Trying to redefine input variable: '" & $var_name_str & "'", var_name)
            elif var_name_str_len == 4:
                if var_name_str[2].isDigit and var_name_str[3].isDigit:
                    error("Trying to redefine input variable: '" & $var_name_str & "'", var_name)
            elif var_name_str_len == 5:
                if var_name_str[2].isDigit and var_name_str[3].isDigit and var_name_str[5].isDigit:
                    error("Trying to redefine input variable: '" & $var_name_str & "'", var_name)

        if is_command_or_ident:
            if not is_out_variable:          
                let 
                    var_declared_in_scope = nnkCall.newTree(
                        newIdentNode("not"),
                        nnkCall.newTree(
                            newIdentNode("declaredInScope"),
                            var_name
                        ),
                    )

                    assignment_statement = nnkStmtList.newTree(
                        nnkAsgn.newTree(
                            var_name,
                            nnkCall.newTree(
                                nnkCall.newTree(
                                    newIdentNode("typeof"),
                                    var_name
                                ),
                                asgn_right
                            )
                        )
                    )

                #init / def
                if not is_perform_block and not is_sample_block:
                    #If already declared, no need to run declaredInScope
                    if var_already_declared:
                        parsed_statement = assignment_statement
                    #Else, check declaredInScope
                    else:
                        parsed_statement = nnkStmtList.newTree(
                            nnkWhenStmt.newTree(
                                nnkElifBranch.newTree(
                                    var_declared_in_scope,
                                    nnkStmtList.newTree(
                                        nnkVarSection.newTree(
                                            asgn_left
                                        )
                                    )
                                ),
                                nnkElse.newTree(
                                    assignment_statement
                                )
                            )
                        )

                # perform / sample
                else:
                    #If already declared, no need to run declaredInScope
                    if var_already_declared:
                        parsed_statement = assignment_statement
                    #Else, check declaredInScope AND omni_build_names
                    else:
                        let 
                            omni_build_names = newIdentNode("omni_build_names")
                            var_name_lit = newLit(
                                var_name.strVal()
                            )

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
                                                    omni_build_names
                                                )
                                            )
                                        ),
                                        var_declared_in_scope
                                    ),
                                    nnkStmtList.newTree(
                                        nnkVarSection.newTree(
                                            asgn_left
                                        )
                                    )
                                ),
                                nnkElse.newTree(
                                    assignment_statement
                                )
                            )
                        )  

            #out1 = ... (ONLY in perform / sample blocks)
            else:
                if is_perform_block or is_sample_block:
                    parsed_statement = nnkAsgn.newTree(
                        var_name,
                        nnkCall.newTree(
                            nnkCall.newTree(
                                newIdentNode("typeof"),
                                var_name
                            ),
                            asgn_right
                        )
                    )

        #outs[i] in perform block (already been checked)
        elif is_outs_brackets:
            let audio_index_loop_bracket = nnkWhenStmt.newTree(
                nnkElifExpr.newTree(
                    nnkCall.newTree(
                        newIdentNode("declared"),
                        newIdentNode("omni_audio_index")
                    ),
                    nnkStmtList.newTree(
                        nnkBracketExpr.newTree(
                            nnkBracketExpr.newTree(
                                newIdentNode("omni_outs_ptr"),
                                nnkCall.newTree(
                                    newIdentNode("int"),
                                    bracket_index
                                )  
                            ),
                            newIdentNode("omni_audio_index")
                        )
                    )
                ),
                nnkElseExpr.newTree(
                    nnkBracketExpr.newTree(
                        newIdentNode("omni_outs_ptr"),
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
                                    asgn_right
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
                        asgn_right
                    )
                )
            )

    return parsed_statement

#Parse the dot syntax: .
proc omni_parse_untyped_dot(statement : NimNode, level : var int, declared_vars : var seq[string], is_init_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false, extra_data : NimNode) : NimNode {.compileTime.} =
    var parsed_statement = omni_parser_untyped_loop(statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)
    
    #Data.new -> normal Data() constructor call
    let dot_right = parsed_statement[1]
    if dot_right.kind == nnkIdent:
        if dot_right.strVal() == "new":
            let dot_left = parsed_statement[0]
            parsed_statement = nnkCall.newTree(dot_left)
            parsed_statement = omni_find_struct_constructor_call(parsed_statement)

    return parsed_statement

#Parse the square bracket syntax: []
proc omni_parse_untyped_brackets(statement : NimNode, level : var int, declared_vars : var seq[string], is_init_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false, extra_data : NimNode) : NimNode {.compileTime.} =
    #Parse the whole statement first
    var parsed_statement = omni_parser_untyped_loop(statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data) #keep parsing the entry of the bracket expr

    let 
        bracket_ident = parsed_statement[0]
        bracket_val   = parsed_statement[1]

    if bracket_ident.kind == nnkIdent:
        let bracket_ident_str = bracket_ident.strVal()

        #Look for ins[i]
        if bracket_ident_str == "ins":
            let omni_audio_index =  nnkWhenStmt.newTree(
                nnkElifExpr.newTree(
                    nnkCall.newTree(
                        newIdentNode("declared"),
                        newIdentNode("omni_audio_index")
                    ),
                    nnkStmtList.newTree(
                        newIdentNode("omni_audio_index")
                    )
                ),
                nnkElseExpr.newTree(
                    nnkStmtList.newTree(
                        newLit(0)
                    )
                )
            )
            
            parsed_statement = nnkCall.newTree(
                newIdentNode("omni_get_dynamic_input"),
                newIdentNode("omni_ins_ptr"),
                bracket_val,
                omni_audio_index
            )

        #Look for params[i]
        elif bracket_ident_str == "params":
            parsed_statement = nnkCall.newTree(
                newIdentNode("omni_get_dynamic_param"),
                bracket_val
            )

        #Look for buffers[i]
        elif bracket_ident_str == "buffers":
            parsed_statement = nnkCall.newTree(
                newIdentNode("omni_get_dynamic_buffer"),
                bracket_val
            )

    return parsed_statement

proc copy_declared_vars(declared_vars : seq[string]) : seq[string] {.inline.} =
    var declared_vars_copy : seq[string]
    for declared_var in declared_vars:
        declared_vars_copy.add(declared_var)
    return declared_vars_copy

proc reset_declared_vars(declared_vars : var seq[string], declared_vars_copy : seq[string]) : void {.inline.} =
    declared_vars.reset()
    for declared_var_copy in declared_vars_copy:
        declared_vars.add(declared_var_copy)

proc omni_parse_untyped_elif_else_for_while_block(statement : NimNode, level : var int, declared_vars : var seq[string], is_init_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false, extra_data : NimNode) : NimNode {.compileTime.} =
    #Copy the vars that were declared in the previous scope
    var declared_vars_copy = declared_vars.copy_declared_vars()

    #Ok, go through with the parsing of the elif / else / for / while statements
    var parsed_statement = omni_parser_untyped_loop(statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)

    #Reset declared vars, so they won't affect other scopes!
    declared_vars.reset_declared_vars(declared_vars_copy)
    
    return parsed_statement

#Dispatcher logic
proc omni_parser_untyped_dispatcher(statement : NimNode, level : var int, declared_vars : var seq[string], is_init_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false, extra_data : NimNode) : NimNode {.compileTime.} =
    let statement_kind = statement.kind
    
    var parsed_statement : NimNode

    if statement_kind   == nnkCall:
        parsed_statement = omni_parse_untyped_call(statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)
    elif statement_kind == nnkCommand:
        parsed_statement = omni_parse_untyped_command(statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)
    elif statement_kind == nnkAsgn:
        parsed_statement = omni_parse_untyped_assign(statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)
    elif statement_kind == nnkDotExpr:
        parsed_statement = omni_parse_untyped_dot(statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)
    elif statement_kind == nnkBracketExpr:
        parsed_statement = omni_parse_untyped_brackets(statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)
    elif statement_kind == nnkExprEqExpr:
        parsed_statement = omni_parse_untyped_expr_eq_expr(statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)
    
    #parse return statement just like calls, to detect constructors!
    elif statement_kind == nnkReturnStmt:
        parsed_statement = omni_parse_untyped_call(statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)
    
    #This is needed to introduce new scopes, in order for declared_vars to work everytime on a different scope level
    elif statement_kind == nnkElifBranch or statement_kind == nnkElse or statement_kind == nnkForStmt or statement_kind == nnkWhileStmt or statement_kind == nnkBlockStmt:
        parsed_statement = omni_parse_untyped_elif_else_for_while_block(statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)
    
    #This is to count ins
    elif statement_kind == nnkIdent:
        if is_perform_block or is_sample_block:
            if statement.strVal().startsWith("in"):
                check_highest_in(statement)
        parsed_statement = statement
    
    #Loop and dispatch
    else:
        parsed_statement = omni_parser_untyped_loop(statement, level, declared_vars, is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)

    return parsed_statement
    
#Entry point: Parse entire block
proc omni_parse_untyped_block_inner(code_block : NimNode, declared_vars : var seq[string], is_init_block : bool = false, is_perform_block : bool = false, is_sample_block : bool = false, is_def_block : bool = false, extra_data : NimNode) : void {.compileTime.} =
    for index, statement in code_block:
        #Initial level, 0
        var level : int = 0
        let parsed_statement = omni_parser_untyped_dispatcher(statement, level, declared_vars,  is_init_block, is_perform_block, is_sample_block, is_def_block, extra_data)

        #Replaced the parsed_statement
        if parsed_statement != nil:
            code_block[index] = parsed_statement

macro omni_parse_block_untyped*(code_block_in : untyped, is_init_block_typed : typed = false, is_perform_block_typed : typed = false, is_sample_block_typed : typed = false, is_def_block_typed : typed = false, extra_data : untyped = nil) : untyped =
    var 
        #used to wrap the whole code_block in a block: statement to create a closed environment to be semantically checked, and not pollute outer scope with symbols.
        final_block = nnkBlockStmt.newTree(
            newEmptyNode()
        )

        code_block  = code_block_in

        declared_vars : seq[string]

    let 
        is_init_block = is_init_block_typed.boolVal()
        is_perform_block = is_perform_block_typed.boolVal()
        is_sample_block = is_sample_block_typed.boolVal()
        is_def_block = is_def_block_typed.boolVal()

    #Sample block without perform
    if is_sample_block:
        code_block = omni_parse_sample_block(code_block)

    #Standard perform block (is_sample_block is false here too)
    elif is_perform_block:
        var found_sample_block = false
        
        #Perhaps this loop can easily be moved in the parse_block function altogether
        for index, statement in code_block:
            if statement.kind == nnkCall:
                let 
                    var_ident = statement[0]
                    var_misc  = statement[1]
                
                #Look for the sample block inside of perform
                if var_ident.strVal == "sample":
                    let sample_block = var_misc
                    #Replace the sample: block with the new parsed one.
                    code_block[index] = omni_parse_sample_block(sample_block)
                    found_sample_block = true
                    break
            
        #couldn't find sample block IN perform block
        if not found_sample_block:
            error("'perform': no 'sample' block provided, or not at top level.", code_block)
        
    var build_statement : NimNode
    if is_init_block:
        #Remove "build" statement from the block before all syntactic analysis.
        #This is needed for this to work:
        #build:
        #   phase
        #   somethingElse
        #This build_statement will then be passed to the next analysis part in order to be re-added at the end of all the parsing.
        let code_block_last = code_block.last()
        if code_block_last.kind == nnkCall or code_block_last.kind == nnkCommand:
            let 
                code_block_last_first = code_block_last[0]
                code_block_last_first_kind = code_block_last_first.kind
            if code_block_last_first_kind == nnkIdent or code_block_last_first_kind == nnkSym:
                if code_block_last_first.strVal() == "build":
                    build_statement = code_block_last
                    #Delete "build" from the code_block.
                    #It will be added back again at the end of the typed evaluation
                    code_block.del(code_block.len() - 1)

    #Add ins / params / buffers to declared vars for init / perform / sample. This allows not to allow to redefine them (but you can in a def)
    if not is_def_block:
        declared_vars.add(omni_ins_names_list)
        declared_vars.add(omni_params_names_list)
        declared_vars.add(omni_buffers_names_list)

    #Begin parsing
    omni_parse_untyped_block_inner(
        code_block, 
        declared_vars,
        is_init_block, 
        is_perform_block, 
        is_sample_block, 
        is_def_block, 
        extra_data
    )

    #final block. it's a block stmt
    final_block.add(code_block)
    
    #If perform or sample block:
    #1) Run ins / outs according to dynamic input count
    #2) Define init if needed
    #3) Store the untyped perform code as a template. The parsed code generation will run at a second stage (inside the perform functions)
    if is_perform_block or is_sample_block:
        let 
            declare_ins = nnkWhenStmt.newTree(
                nnkElifBranch.newTree(
                    nnkCall.newTree(
                        newIdentNode("not"),
                        nnkCall.newTree(
                            newIdentNode("declared"),
                            newIdentNode("omni_declared_inputs")
                        )
                    ),
                    nnkStmtList.newTree(
                        nnkCommand.newTree(
                            newIdentNode("ins"),
                            newLit(omni_highest_in)
                        )
                    )
                )
            )

            declare_outs = nnkWhenStmt.newTree(
                nnkElifBranch.newTree(
                    nnkCall.newTree(
                        newIdentNode("not"),
                        nnkCall.newTree(
                            newIdentNode("declared"),
                            newIdentNode("omni_declared_outputs")
                        )
                    ),
                    nnkStmtList.newTree(
                        nnkCommand.newTree(
                            newIdentNode("outs"),
                            newLit(omni_highest_out)
                        )
                    )
                )
            )

            perform_untyped_block = nnkTemplateDef.newTree(
                newIdentNode("omni_perform_untyped_block"),
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
                    final_block
                )
            )

        return nnkStmtList.newTree(
            declare_ins,
            declare_outs,   
            perform_untyped_block
        )

    #Run the typed version of the macro on the produced code
    return quote do:
        omni_parse_block_typed(
            `final_block`, 
            `build_statement`, 
            `is_init_block_typed`, 
            `is_perform_block_typed`, 
            `is_def_block_typed`
        )

# ============================== #
# Stage 2: Typed code generation #
# ============================== #

#Forward declaration
proc omni_parser_typed_dispatcher(statement : NimNode, level : var int, is_init_block : bool = false, is_perform_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.}

#Loop around statement and trigger dispatch, performing code substitution
proc omni_parser_typed_loop(statement : NimNode, level : var int, is_init_block : bool = false, is_perform_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    var parsed_statement = statement
    if statement.len > 0:
        for index, statement_inner in statement:
            #Substitute old content with the parsed one
            parsed_statement[index] = omni_parser_typed_dispatcher(statement_inner, level, is_init_block, is_perform_block, is_def_block)
    return parsed_statement

#Parse the call syntax: function(arg)
proc omni_parse_typed_call(statement : NimNode, level : var int, is_init_block : bool = false, is_perform_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    var parsed_statement = omni_parser_typed_loop(statement, level, is_init_block, is_perform_block, is_def_block)

    let function_call = parsed_statement[0]

    if function_call.kind == nnkSym or function_call.kind == nnkIdent:
        
        let function_name = function_call.strVal()

        #Fix Data/Buffer access: from []=(delay_data, phase, write_value) to delay_data[phase] = write_value
        if function_name == "[]=":                
            #1 channel
            if parsed_statement[1].kind == nnkDotExpr:
                
                var asgn_right = parsed_statement[3]

                #Remove typeof() which has been added in untyped section for tuple access safety
                if asgn_right.kind == nnkConv:
                    if asgn_right.len == 2:
                        if asgn_right[0].kind == nnkTypeOfExpr:
                            asgn_right = asgn_right[1]

                parsed_statement = nnkAsgn.newTree(
                    nnkBracketExpr.newTree(
                        parsed_statement[1],
                        parsed_statement[2]
                    ),
                    asgn_right
                )

            #Multi channel
            else:
                let bracket_expr = nnkBracketExpr.newTree(parsed_statement[1])

                #Extract indices
                for channel_index in 2..parsed_statement.len-2:
                    bracket_expr.add(parsed_statement[channel_index])

                var asgn_right = parsed_statement.last()

                #Remove typeof() which has been added in untyped section for tuple access safety
                if asgn_right.kind == nnkConv:
                    if asgn_right.len == 2:
                        if asgn_right[0].kind == nnkTypeOfExpr:
                            asgn_right = asgn_right[1]

                parsed_statement = nnkAsgn.newTree(
                    bracket_expr,
                    asgn_right
                )

        #If a omni_struct_new call, figure out generics from the omni_struct_type argument!
        elif function_name.endsWith("_omni_struct_new"):
            discard

            #[ #omni_struct_type is the third last argument, retrieve it
            var omni_struct_type = parsed_statement[^3]

            #Ok, some generics input from user. Attach it to the func call
            if omni_struct_type.kind == nnkBracketExpr:
                let struct_impl = omni_struct_type[0].getImpl()
            
                if struct_impl.kind != nnkNilLit:
                    #Need to offset in order to find starting argument potition of generics.
                    #-2 is to take in account _struc_new_inner name in parsed_statement and _omni_struct_ptr name in omni_struct_type
                    let parsed_statement_offset = parsed_statement.len - omni_struct_type.len - 2

                    for i, generic_type in omni_struct_type:
                        #Skip _omni_struct_ptr name
                        if i == 0:
                            continue

                        parsed_statement[i-1 + parsed_statement_offset] = generic_type ]#

        #Check type of all arguments for other function calls (not array access related) 
        #Ignore function ending in _min_max (the one used for input min/max conditional) OR omni_get_dynamic_input
        #THIS IS NOT SAFE! min_max could be assigned by user to another def
        elif parsed_statement.len > 1 and not(function_name.endsWith("_omni_min_max")) and not(function_name == "omni_get_dynamic_input"):
            for i, arg in parsed_statement:
                #ignore i == 0 (the function_name)
                if i == 0:
                    continue

                #Only check if actually it's possible to get the type (it's a sym). Something like safediv would be ident
                if arg.kind == nnkSym:
                    let arg_type = arg.getTypeInst().getTypeImpl()

                    #Check validity of each argument to function
                    omni_check_valid_type(arg_type, $i, is_proc_call=true, proc_name=function_name)

    return parsed_statement

#Let nim figure out when doing explicit conversions (on all levels) or variable assignments (only at top level)
proc omni_find_explicit_conversions(call : NimNode) : bool {.compileTime.} =
    if call.kind == nnkConv:
        return true

    if call.kind == nnkCall or call.kind == nnkInfix or call.kind == nnkPostfix:
        for statement in call:
            if statement.kind == nnkConv:
                return true
            elif statement.kind == nnkCall:
                return omni_find_explicit_conversions(statement)
    return false
    
proc omni_build_new_tuple_recursive(tuple_constr : NimNode, tuple_type : NimNode) {.compileTime.} =
    for i, tuple_entry_type in tuple_type:
        if tuple_constr.len <= i:
            continue #or break?

        #Make sure not to have mismatches between tuple_type and tuple_constr (e.g. when building from functions)
        let tuple_entry_val = tuple_constr[i]

        #If another tuple, run again
        if tuple_entry_val.kind == nnkTupleConstr:
            if tuple_entry_type.kind == nnkTupleConstr:
                omni_build_new_tuple_recursive(tuple_entry_val, tuple_entry_type)
        
        #Wrap each entry in float() if needed
        else:
            let tuple_entry_type_kind = tuple_entry_type.kind
            if tuple_entry_type_kind == nnkSym or tuple_entry_type_kind == nnkIdent:
                let tuple_entry_type_str = tuple_entry_type.strVal()

                #[
                var valid_convert_func = false
                
                #Check if there already is a float / int / ... conversion with nnkConv
                #which could've been applied if explicit types were set by user
                if tuple_entry_val.kind == nnkConv:
                    let func_name = tuple_entry_val[0].strVal()
                    if func_name in valid_number_types:
                        valid_convert_func = true
                ]#

                #Find out if there are any explicit conversions happening in code. If there are,
                #let nim figure out the type for that entry (and let the user figure it out)
                let explicit_conversions = omni_find_explicit_conversions(tuple_entry_val)

                #Run conversion to float if type is not explicitly set with a conversion
                if not explicit_conversions and tuple_entry_type_str in omni_tuple_convert_types:
                    tuple_constr[i] = nnkCall.newTree(
                        newIdentNode("float"),
                        tuple_entry_val
                    )

#Convert all float types (float32, cfloat, etc...) to float.
#statement comes in as a nnkVarSection
proc omni_convert_float_tuples(parsed_statement : NimNode, ident_defs : NimNode, var_symbol : NimNode, var_decl_type : NimNode, var_content : NimNode, var_name : string, tuple_type : NimNode) : NimNode {.compileTime.} =
    #If var_decl_type is not empty, it means it's been expressed by the user already
    #and dealt with in the untyped block already. Just return
    if var_decl_type.kind != nnkEmpty:
        return parsed_statement
    
    var 
        real_var_content : NimNode
        var_content_kind = var_content.kind

    #Weird conversion case? Should I just skip over?? It happens when returning from a def
    if var_content_kind == nnkHiddenSubConv:
        real_var_content = var_content[1]
        var_content_kind = real_var_content.kind
    else:
        real_var_content = var_content

    if var_content_kind == nnkEmpty:
        error("'" & $var_name & "': trying to build an empty tuple", parsed_statement)
    
    #Detect if it's a proper tuple construct (e.g. a = (1, 2), and not a = someTupleFunc())
    if var_content_kind == nnkTupleConstr:
        #real_var_content is modified in place, and it's part of ident_defs anyway.
        omni_build_new_tuple_recursive(real_var_content, tuple_type)
        
        return nnkVarSection.newTree(
            ident_defs
        )

    else:
        #Perhaps at least do the type info here??
        return parsed_statement

#Parse the var section
proc omni_parse_typed_var_section(statement : NimNode, level : var int, is_init_block : bool = false, is_perform_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    var parsed_statement = omni_parser_typed_loop(statement, level, is_init_block, is_perform_block, is_def_block)

    let 
        ident_defs    = parsed_statement[0]
        var_symbol    = ident_defs[0]
        var_decl_type = ident_defs[1]
        var_content   = ident_defs[2]   
        var_type      = var_symbol.getTypeInst().getTypeImpl()
        var_type_kind = var_type.kind
        var_name      = var_symbol.strVal()        

    if var_name in omni_invalid_variable_names:
        error("'" & $var_name & "' is an invalid variable name: it's the name of an in-built type.", statement)

    #Check if it's a valid type
    omni_check_valid_type(var_type, var_name)

    #Look for structs
    if var_type_kind == nnkPtrTy:
        #Found a struct!
        if var_type.omni_is_struct():
            #Detect if it's a non-initialized struct variable (e.g "data Data[float]")
            if ident_defs.len == 3:
                if var_content.kind == nnkEmpty:
                    error("'" & var_name & "': structs must be instantiated on declaration.", statement)
            
            #All good, create new let statement
            let new_let_statement = nnkLetSection.newTree(
                ident_defs
            )

            #Replace the entry in the untyped block, which has yet to be semantically evaluated.
            parsed_statement = new_let_statement

    #Look for tuples. They come in as "var".
    #Should they be "let" or "var" ???
    elif var_type_kind == nnkTupleConstr:
        parsed_statement = omni_convert_float_tuples(parsed_statement, ident_defs, var_symbol, var_decl_type, var_content, var_name, var_type)
        #error repr parsed_statement

        #Look for consts: capital letters.
        #Same rules apply: MYCONST = (1, 2) -> MYCONST = (float(1), float(2)) / MYCONST (int, float) = (1, 2) -> MYCONST (int, float) = (1, float(2))
        if var_name.isStrUpperAscii(true):
            let old_statement_body = parsed_statement[0]

            #Create new let statement
            let new_let_statement = nnkLetSection.newTree(
                old_statement_body
            )

            parsed_statement = new_let_statement
    
    #Standard var declarations. Declare as float if not specified in the var decl:
    # a = 0 -> a float = float(0)
    # a int = 0 -> a int = 0
    # a = int(0) -> a = int(0)
    # a = int(13) + int(12) -> a = int(13) + int(12)
    else:
        #Keep boleans as they are
        var is_bool = false
        if var_type_kind == nnkSym:
            if var_type.strVal() == "bool":
                is_bool = true

        #This makes a = int(1.5) + int(0.432) work!! Lets nim figure out typing if nnkConv are present in the var decl
        let explicit_conversions = omni_find_explicit_conversions(var_content)

        #if explicit_conversions:
        #    error var_name

        #if var_content.kind != nnkConv makes sure that
        #conversion calls are kept as they are! e.g. a = int(0) should still be int.
        #This won't make this an int though: a = int(1.5) + int(0.5).
        #For the old behaviour (with conversions to float on anything user doesn't specify), remove var_content.kind != nnkConv
        #if var_content.kind != nnkConv and var_decl_type.kind == nnkEmpty and is_bool.not:
        
        #This works even with a = int(1.5) + int(0.5)
        if not explicit_conversions and var_decl_type.kind == nnkEmpty and is_bool.not:
            parsed_statement = nnkVarSection.newTree(
                nnkIdentDefs.newTree(
                    var_symbol,
                    newIdentNode("float"),
                    nnkCall.newTree(
                        newIdentNode("float"),
                        var_content
                    )
                )
            )

        #Look for consts: capital letters.
        #Same rules apply: MYCONST = 1 -> MYCONST float = float(1) / MYCONST int = 1 -> MYCONST int = 1
        if var_name.isStrUpperAscii(true):
            let old_statement_body = parsed_statement[0] #Use the new parsed_statement, not ident_defs

            #Create new let statement
            let new_let_statement = nnkLetSection.newTree(
                old_statement_body
            )

            parsed_statement = new_let_statement

    return parsed_statement

#Used in defs for "return",
#This is needed in order to avoid type checking with "return" statements!
proc omni_parse_typed_let_section(statement : NimNode, level : var int, is_init_block : bool = false, is_perform_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    var parsed_statement = omni_parser_typed_loop(statement, level, is_init_block, is_perform_block, is_def_block)

    if is_def_block:
        let 
            ident_defs = parsed_statement[0]
            var_name = ident_defs[0]

        #Convert "omni_temp_result = xyz" to "return xyz" statements
        if var_name.strVal().startsWith("omni_temp_result"):
            var return_content = ident_defs[2]

            #If a tuple, run conversions!
            if return_content.kind == nnkTupleConstr:
                let tuple_type = return_content.getTypeInst().getTypeImpl()
                #return content is modified in place
                omni_build_new_tuple_recursive(return_content, tuple_type)

            parsed_statement = nnkReturnStmt.newTree(
                return_content
            )
    
    return parsed_statement

proc omni_parse_typed_infix(statement : NimNode, level : var int, is_init_block : bool = false, is_perform_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    var parsed_statement = omni_parser_typed_loop(statement, level, is_init_block, is_perform_block, is_def_block)

    assert parsed_statement.len == 3

    var infix_symbol = parsed_statement[0]

    if infix_symbol.kind == nnkOpenSymChoice:
        infix_symbol = infix_symbol[0]

    let infix_str    = infix_symbol.strVal()

    #This is necessary (even if function is defined properly in omni_math) because
    #it will work also for all the standard nim cases that will not trigger the specific `/` implementation,
    #making all division / modulus operations safe
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

proc omni_parse_typed_asgn(statement : NimNode, level : var int, is_init_block : bool = false, is_perform_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    var 
        parsed_statement = omni_parser_typed_loop(statement, level, is_init_block, is_perform_block, is_def_block)
        asgn_left  = parsed_statement[0]
        asgn_left_kind = asgn_left.kind

    #Ignore 'result' (which is used in return stmt)
    if asgn_left_kind == nnkSym:
        if asgn_left.strVal() == "result":
            return parsed_statement

    if omni_is_struct(asgn_left):
        if asgn_left_kind == nnkDotExpr:
            error("'" & repr(asgn_left) & "': trying to re-assign an already allocated struct field.", asgn_left)
        else:
            error("'" & repr(asgn_left) & "': trying to re-assign an already allocated struct.", asgn_left)

    #Check if trying to re-assign length / samplerate / channels of a Buffer
    if asgn_left_kind == nnkDotExpr:
        var
            left_dot = asgn_left[0]
            right_dot = asgn_left[1]
            left_type_inst = left_dot.getTypeInst()

        if left_type_inst.kind == nnkSym:
            let left_type_inst_str = left_type_inst.strVal()
            if left_type_inst_str == "Buffer" or left_type_inst_str == "Buffer_omni_struct":
                if right_dot.kind == nnkSym:
                    let right_dot_str = right_dot.strVal()
                    if right_dot_str == "samplerate" or right_dot_str == "length" or right_dot_str == "channels":
                        error("'" & repr(parsed_statement) & "': can't reassign a Buffer's '" & right_dot_str & "'", right_dot)

    ##########################################################################
    #CHECK FOR SAME TYPE TO REMOVE EVENTUAL EXCESSIVE TYPEOF() CALLS HERE !!!!
    ##########################################################################

    return parsed_statement

#Substitute the entry name with data[i], and the let section with assignment
proc omni_substitute_for_loop(code_block : NimNode, entry : NimNode, substitution : NimNode) : void =
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
            omni_substitute_for_loop(statement, entry, substitution)

#This parses for loops.
#It's used to do so:
#a = Data[Something](10)
#for entry in a:
#   entry = Something()
#OR
#for i, entry in a:
#   entry = Something(i)
proc omni_parse_typed_for(statement : NimNode, level : var int, is_init_block : bool = false, is_perform_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    var 
        parsed_statement = omni_parser_typed_loop(statement, level, is_init_block, is_perform_block, is_def_block)
        index1 = parsed_statement[0]
        index2 = parsed_statement[1]

    #for i, entry in data:
    if index2.kind == nnkSym:
        if parsed_statement[2].kind != nnkInfix:
            let 
                index = index1
                entry = index2
                data_name = parsed_statement[2][1]

                data_chan = genSym(ident="data_chan")
                data_index = genSym(ident="data_index") #unique symbol generation
               
                bracket_expr = nnkBracketExpr.newTree(
                    data_name,
                    data_chan,
                    data_index
                )
                
            let check_data = data_name.getTypeInst()
            var is_data = false
            if check_data.kind == nnkBracketExpr:
                let check_data_first_entry = check_data[0]
                if check_data_first_entry.kind == nnkSym:
                    let check_data_first_entry_str = check_data_first_entry.strVal()
                    if check_data_first_entry_str == "Data" or check_data_first_entry_str == "Data_omni_struct_ptr":
                        is_data = true
            elif check_data.kind == nnkPtrTy:
                let check_data_first_entry = check_data[0]
                if check_data_first_entry.kind == nnkBracketExpr:
                    if check_data_first_entry[0].kind == nnkSym:
                        if check_data_first_entry[0].strVal() == "Data_omni_struct":
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

                omni_substitute_for_loop(for_loop_body, entry, bracket_expr)

                for_loop_body = nnkStmtList.newTree(
                    for_loop_body,
                    nnkInfix.newTree(
                        newIdentNode("+="),
                        index,
                        newLit(1)
                    )
                )

                parsed_statement = nnkBlockStmt.newTree(
                    newEmptyNode(),
                    nnkStmtList.newTree(
                        nnkVarSection.newTree(
                            nnkIdentDefs.newTree(
                                index,
                                newEmptyNode(),
                                newLit(0)
                            )
                        ),
                        nnkForStmt.newTree(
                            data_chan,
                            nnkInfix.newTree(
                                newIdentNode("..<"),
                                newLit(0),
                                nnkCall.newTree(
                                    newIdentNode("chans"),
                                    data_name
                                )
                            ),
                            nnkForStmt.newTree(
                                data_index,
                                nnkInfix.newTree(
                                    newIdentNode("..<"),
                                    nnkCall.newTree(
                                        newIdentNode("len"),
                                        data_name
                                    )
                                ),
                                for_loop_body,
                            )
                        )
                    )
                )
        
    #for entry in data:
    else:
        if parsed_statement[1].kind != nnkInfix:
            let 
                entry = index1
                data_name = parsed_statement[1][1]
                
                data_chan = genSym(ident="data_chan")
                data_index = genSym(ident="data_index") #unique symbol generation
               
                bracket_expr = nnkBracketExpr.newTree(
                    data_name,
                    data_chan,
                    data_index
                )
            
            let check_data = data_name.getTypeInst()

            var is_data = false
            if check_data.kind == nnkBracketExpr:
                let check_data_first_entry = check_data[0]
                if check_data_first_entry.kind == nnkSym:
                    let check_data_first_entry_str = check_data_first_entry.strVal()
                    if check_data_first_entry_str == "Data" or check_data_first_entry_str == "Data_omni_struct_ptr":
                        is_data = true
            elif check_data.kind == nnkPtrTy:
                let check_data_first_entry = check_data[0]
                if check_data_first_entry.kind == nnkBracketExpr:
                    if check_data_first_entry[0].kind == nnkSym:
                        if check_data_first_entry[0].strVal() == "Data_omni_struct":
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

                omni_substitute_for_loop(for_loop_body, entry, bracket_expr)

                parsed_statement = nnkForStmt.newTree(
                    data_chan,
                    nnkInfix.newTree(
                        newIdentNode("..<"),
                        newLit(0),
                        nnkCall.newTree(
                            newIdentNode("chans"),
                            data_name
                        )
                    ),
                    nnkForStmt.newTree(
                        data_index,
                        nnkInfix.newTree(
                            newIdentNode("..<"),
                            newLit(0),
                            nnkCall.newTree(
                                newIdentNode("len"),
                                data_name
                            )
                        ),
                        for_loop_body
                    )
                )

        #Replace explicit const values in loops (gcc will optimize those)
        else:
            let var_name = index2[2]
            if var_name.kind == nnkSym:
                let var_name_str = var_name.strVal()
                if var_name_str.isStrUpperAscii(true): #if a const
                    let var_ident_defs = var_name.getImpl()
                    if var_ident_defs.kind == nnkIdentDefs:
                        let var_impl_val = var_ident_defs[2] #actual decl var
                        if var_impl_val.kind == nnkIntLit:
                            index2[2] = newLit(int(var_impl_val.intVal()))
                        elif var_impl_val.kind == nnkFloatLit:
                            index2[2] = newLit(int(var_impl_val.floatVal()))

    return parsed_statement

#Wrap if expressions and case statements in parenthesis. This is especially useful for the params[i] / buffers[i] interface, which uses a case statement
# let a = if b: 0 else: 1 -> let a = (if b: 0 else: 1)
# let a = case b: of 0: 0 else: 1 -> let a = (case b: of 0: 0 else: 1)
proc omni_parse_typed_if_expr_case_stmt(statement : NimNode, level : var int, is_init_block : bool = false, is_perform_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    var parsed_statement = omni_parser_typed_loop(statement, level, is_init_block, is_perform_block, is_def_block)
    parsed_statement = nnkPar.newTree(
        parsed_statement
    )
    return parsed_statement
    
#Dispatcher logic
proc omni_parser_typed_dispatcher(statement : NimNode, level : var int, is_init_block : bool = false, is_perform_block : bool = false, is_def_block : bool = false) : NimNode {.compileTime.} =
    let statement_kind = statement.kind
    
    var parsed_statement : NimNode

    if statement_kind   == nnkCall:
        parsed_statement = omni_parse_typed_call(statement, level, is_init_block, is_perform_block, is_def_block)
    elif statement_kind == nnkVarSection:
        parsed_statement = omni_parse_typed_var_section(statement, level, is_init_block, is_perform_block, is_def_block)
    elif statement_kind == nnkLetSection:
        parsed_statement = omni_parse_typed_let_section(statement, level, is_init_block, is_perform_block, is_def_block)
    elif statement_kind == nnkInfix:
        parsed_statement = omni_parse_typed_infix(statement, level, is_init_block, is_perform_block, is_def_block)
    elif statement_kind == nnkAsgn:
        parsed_statement = omni_parse_typed_asgn(statement, level, is_init_block, is_perform_block, is_def_block)
    elif statement_kind == nnkForStmt:
        parsed_statement = omni_parse_typed_for(statement, level, is_init_block, is_perform_block, is_def_block)
    elif statement_kind == nnkIfExpr or statement_kind == nnkCaseStmt:
        parsed_statement = omni_parse_typed_if_expr_case_stmt(statement, level, is_init_block, is_perform_block, is_def_block)
    else:
        parsed_statement = omni_parser_typed_loop(statement, level, is_init_block, is_perform_block, is_def_block)

    return parsed_statement
    
#Entry point: Parse entire block
proc omni_parse_typed_block_inner(code_block : NimNode, is_init_block : bool = false, is_perform_block : bool = false, is_def_block : bool = false) : void {.compileTime.} =
    for index, statement in code_block:
        #Initial level, 0
        var level : int = 0
        let parsed_statement = omni_parser_typed_dispatcher(statement, level, is_init_block, is_perform_block, is_def_block)

        #Replaced the parsed_statement
        if parsed_statement != nil:
            code_block[index] = parsed_statement

#This allows to check for types of the variables and look for structs to declare them as let instead of var
macro omni_parse_block_typed*(typed_code_block : typed, build_statement : untyped = nil, is_init_block_typed : typed = false, is_perform_block_typed : typed = false, is_def_block_typed : typed = false) : untyped =
    let 
        is_init_block = is_init_block_typed.strVal() == "true"
        is_perform_block = is_perform_block_typed.strVal() == "true"
        is_def_block = is_def_block_typed.strVal() == "true"

    #Extract the body of the block: [0] is an emptynode
    var inner_block = typed_code_block[1].copy()

    #And also wrap it in a StmtList (if it wasn't a StmtList already)
    if inner_block.kind != nnkStmtList:
        inner_block = nnkStmtList.newTree(inner_block)

    #Run the actual typed parsing
    omni_parse_typed_block_inner(
        inner_block, 
        is_init_block, 
        is_perform_block, 
        is_def_block
    )

    #Will return an untyped code block!
    result = typed_to_untyped(inner_block)

    #if init block, run the omni_init_inner macro on the resulting block.
    if is_init_block:
        #If old untyped code in constructor constructor had a "build" call as last call, 
        #it must be the old untyped "build" call for all parsing to work properly.
        #Otherwise all the _let / _var declaration in Omni_UGen body are screwed
        #If build_statement is nil, it means that it wasn't initialized at it means that there
        #was no "build" call as last statement of the constructor block. Don't add it.
        if build_statement != nil and build_statement.kind != nnkNilLit:
            result.add(build_statement)

        #Run the whole block through the omni_init_inner macro. This will build the actual
        #constructor function, and it will run the untyped version of the "build" macro.
        result = nnkCall.newTree(
            newIdentNode("omni_init_inner"),
            nnkStmtList.newTree(
                result
            )
        )

    #if is_def_block:
    #    error repr result

    #if is_perform_block:
    #   error repr result
