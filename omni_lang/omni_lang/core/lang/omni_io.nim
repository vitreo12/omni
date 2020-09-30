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

import macros, strutils

const omni_max_inputs_outputs_const* = 32

#Some crazy numbers
const 
    RANDOM_FLOAT = -12312418241.1249124194
    BUFFER_FLOAT = -13312418241.1249124194

const acceptedCharsForParamName = {'a'..'z', 'A'..'Z', '0'..'9', '_'}

proc generate_min_max_procs(index : SomeInteger) : NimNode {.compileTime.} =
    let 
        in_num = "in" & $index
        in_min = in_num & "_min"
        in_max = in_num & "_max"
    
    return nnkWhenStmt.newTree(
        nnkElifBranch.newTree(
            nnkCall.newTree(
                newIdentNode("declared"),
                newIdentNode(in_min)
            ),
            nnkStmtList.newTree(
                nnkProcDef.newTree(
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
                    nnkPragma.newTree(
                        newIdentNode("inline")
                    ),
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
            )
        )
    )

proc generate_ar_in_template(index : SomeInteger) : NimNode {.compileTime.} =
    let 
        in_num : string = "in" & $(index)
        in_num_min : string = in_num & "_min"
        in_num_min_max  : string = in_num_min & "_max"

        index_minus_one : int = int(index) - 1

    #Generate template if proc for min max is defined
    return nnkWhenStmt.newTree(
        nnkElifBranch.newTree(
            nnkCall.newTree(
                newIdentNode("declared"),
                newIdentNode(in_num_min)
            ),
            nnkStmtList.newTree(
                nnkTemplateDef.newTree(
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
                            newIdentNode(in_num_min_max),
                            nnkBracketExpr.newTree(
                                nnkBracketExpr.newTree(
                                    newIdentNode("ins_Nim"),
                                    newLit(index_minus_one)
                                ),
                                newIdentNode("audio_index_loop")
                            )
                        )
                    ) 
                )
            )
        ),
        nnkElse.newTree(
            nnkStmtList.newTree(
                nnkTemplateDef.newTree(
                    newIdentNode(in_num),            
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
                                newIdentNode("ins_Nim"),
                                newLit(index_minus_one)
                            ),
                            newIdentNode("audio_index_loop")
                        )
                    )
                )
            )
        )
    )

proc generate_kr_in_template(index : SomeInteger) : NimNode {.compileTime.} =
    let 
        in_num : string = "in" & $(index)
        in_num_min : string = in_num & "_min"
        in_num_min_max  : string = in_num_min & "_max"

        index_minus_one : int = int(index) - 1

    #Generate template if proc for min max is defined
    return nnkWhenStmt.newTree(
        nnkElifBranch.newTree(
            nnkCall.newTree(
                newIdentNode("declared"),
                newIdentNode(in_num_min)
            ),
            nnkStmtList.newTree(
                nnkTemplateDef.newTree(
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
                            newIdentNode(in_num_min_max),
                            nnkBracketExpr.newTree(
                                nnkBracketExpr.newTree(
                                    newIdentNode("ins_Nim"),
                                    newLit(index_minus_one)
                                ),
                                newLit(0)
                            )
                        )
                    ) 
                )
            )
        ),
        nnkElse.newTree(
            nnkStmtList.newTree(
                nnkTemplateDef.newTree(
                    newIdentNode(in_num),            
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
                                newIdentNode("ins_Nim"),
                                newLit(index_minus_one)
                            ),
                            newLit(0)
                        )
                    )
                )
            )
        )
    )


#Generate in1, in2, in3...etc templates
macro generate_inputs_templates*(num_of_inputs : typed, generate_ar : typed, generate_min_max : typed = 0) : untyped =
    var final_statement = nnkStmtList.newTree()

    var 
        num_of_inputs_VAL = num_of_inputs.intVal()
        generate_ar = generate_ar.intVal() #boolVal() doesn't work here.
        generate_min_max = generate_min_max.intVal()

    if generate_min_max == 1:
        for i in 1..num_of_inputs_VAL:
            final_statement.add(generate_min_max_procs(i))

    if generate_ar == 1:
        for i in 1..num_of_inputs_VAL:
            final_statement.add(generate_ar_in_template(i))

    else:
        for i in 1..num_of_inputs_VAL:
            final_statement.add(generate_kr_in_template(i))
    
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
    if param_name[0].isUpperAscii():
        error("ins: input name '" & $param_name & "' must start with a lower case letter.")

    for individualChar in param_name:
        if not (individualChar in acceptedCharsForParamName):
            error("ins: Invalid character '" & $individualChar & $ "' in input name '" & $param_name & "'")

proc extractDefaultMinMax(default_min_max : NimNode, param_name : string) : tuple[defult : float, min : float, max : float] {.compileTime.} =
    let default_min_max_len = default_min_max.len()

    var 
        default_num : float = 0.0
        min_num     : float = RANDOM_FLOAT
        max_num     : float = RANDOM_FLOAT

    #Extract def / min / max values
    for index, value in default_min_max.pairs():
        let value_kind = value.kind

        #{0, 0, 1} / {0, 1} / {0}
        if value_kind == nnkIntLit or value_kind == nnkFloatLit or value_kind == nnkPrefix: #negative number
            var value_num : float
            if value_kind == nnkIntLit:
                value_num = float(value.intVal()) 
            elif value_kind == nnkFloatLit:
                value_num = value.floatVal()
            else:
                #negative number
                if value[0].strVal() != "-":
                    error("Invalid prefix for input " & $repr(value))
                let number = value[1]
                if number.kind == nnkIntLit:
                    value_num = float(-1 * number.intVal())
                elif number.kind == nnkFloatLit:
                    value_num = (-1 * number.floatVal())
                else:
                    error("Invalid input:" & $repr(value))

            if default_min_max_len == 3:
                case index:
                    of 0:
                        default_num = float32(value_num)
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
            elif default_min_max_len == 1:
                default_num = float32(value_num)

        #{0 0 1} / {0 1} ... This doesn't work with negative numbers yet!
        #[
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

            #echo astGenRepr value
            #echo astGenRepr value[1]

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
                    default_num = float32(default_stmt.intVal())
                elif default_stmt_kind == nnkFloatLit:
                    default_num = float32(default_stmt.floatVal())
                else:
                    error("Invalid syntax for default value of input \"" & $param_name & "\"")

            if min_stmt_kind == nnkIntLit:
                min_num = float(min_stmt.intVal())
            elif min_stmt_kind == nnkFloatLit:
                min_num = min_stmt.floatVal()
            elif min_stmt_kind == nnkPrefix:
                #negative number
                if min_stmt[0].strVal() != "-":
                    error("Invalid prefix for input " & $repr(value))
                let number = min_stmt[1]
                if number.kind == nnkIntLit:
                    min_num = float(-1 * number.intVal())
                elif number.kind == nnkFloatLit:
                    min_num = (-1 * number.floatVal())
                else:
                    error("Invalid input:" & $repr(value))
            else:
                error("Invalid syntax for min value of input \"" & $param_name & "\"")

            if max_stmt_kind == nnkIntLit:
                max_num = float(max_stmt.intVal())
            elif max_stmt_kind == nnkFloatLit:
                max_num = max_stmt.floatVal()
            elif max_stmt_kind == nnkPrefix:
                #negative number
                if max_stmt[0].strVal() != "-":
                    error("Invalid prefix for input " & $repr(value))
                let number = max_stmt[1]
                if number.kind == nnkIntLit:
                    max_num = float(-1 * number.intVal())
                elif number.kind == nnkFloatLit:
                    max_num = (-1 * number.floatVal())
                else:
                    error("Invalid input:" & $repr(value))
            else:
                error("Invalid syntax for max value of input \"" & $param_name & "\"")
        ]#

        elif value_kind == nnkIdent:
            if value.strVal == "Buffer":
                return (0.0, BUFFER_FLOAT, BUFFER_FLOAT)
            else:
                error("Invalid syntax for input \"" & $param_name & "\"")

        else:
            error("Invalid syntax for input \"" & $param_name & "\"")

    return (default_num, min_num, max_num)

proc buildDefaultMinMaxArrays(num_of_inputs : int, default_vals : seq[float32], min_vals : seq[float], max_vals : seq[float]) : NimNode {.compileTime.} =
    let default_vals_len = default_vals.len()

    #Find mismatch. Perhaps user hasn't defined def/min/max for some params
    if num_of_inputs != default_vals_len:
        error("Got " & $num_of_inputs & " number of inputs but only " & $default_vals_len & " default / min / max values.")

    result = nnkStmtList.newTree()
    
    var 
        deafault_min_max_const_section = nnkConstSection.newTree()
        defaults_array_let_section = nnkLetSection.newTree()
        defaults_array_const = nnkConstDef.newTree(
            nnkPragmaExpr.newTree(
                newIdentNode("omni_defaults_const"),
                nnkPragma.newTree(
                    newIdentNode("inject")
                )
            ),
            newEmptyNode()
        )
        defaults_array_let = nnkIdentDefs.newTree(
            nnkPragmaExpr.newTree(
                newIdentNode("omni_defaults_let"),
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

        #Always add defaults, they will be 0 if not specified
        defaults_array_bracket.add(newLit(default_val))

        if min_val != RANDOM_FLOAT and min_val != BUFFER_FLOAT:
            deafault_min_max_const_section.add(
                nnkConstDef.newTree(
                    nnkPragmaExpr.newTree(
                        newIdentNode("in" & $(i_plus_one) & "_min"),
                        nnkPragma.newTree(
                            newIdentNode("inject")
                        )
                    ),
                    newEmptyNode(),
                    newLit(min_val)
                )
            )

        if max_val != RANDOM_FLOAT and max_val != BUFFER_FLOAT:
            deafault_min_max_const_section.add(
                nnkConstDef.newTree(
                    nnkPragmaExpr.newTree(
                        newIdentNode("in" & $(i_plus_one) & "_max"),
                        nnkPragma.newTree(
                            newIdentNode("inject")
                        )
                    ),
                    newEmptyNode(),
                    newLit(max_val)
                )
            )

        #Buffer case. Just create a const that will be checked against at compile time
        if min_val == BUFFER_FLOAT and max_val == BUFFER_FLOAT:
            deafault_min_max_const_section.add(
                nnkConstDef.newTree(
                    nnkPragmaExpr.newTree(
                        newIdentNode("in" & $(i_plus_one) & "_buffer"),
                        nnkPragma.newTree(
                            newIdentNode("inject")
                        )
                    ),
                    newEmptyNode(),
                    newLit(true)
                )
            )

    defaults_array_const.add(defaults_array_bracket)
    deafault_min_max_const_section.add(defaults_array_const)

    defaults_array_let.add(defaults_array_bracket)
    defaults_array_let_section.add(defaults_array_let)

    #Declare min max as const, the array as both const (for static IO at the end of perform) and let (so i can get its memory address for Omni_UGenDefaults())
    result.add(deafault_min_max_const_section)
    result.add(defaults_array_let_section)
    

macro ins*(num_of_inputs : typed, param_names : untyped = nil) : untyped =
    
    var 
        num_of_inputs_VAL : int
        param_names_string : string = ""
        param_names_node : NimNode

        default_vals : seq[float32]
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
    elif num_of_inputs_VAL > omni_max_inputs_outputs_const:
        error("Exceeded maximum number of inputs, " & $omni_max_inputs_outputs_const)

    #init the seqs
    default_vals = newSeq[float32](num_of_inputs_VAL)
    min_vals     = newSeq[float](num_of_inputs_VAL)
    max_vals     = newSeq[float](num_of_inputs_VAL)

    #Fill them with a random float, but keep default's one to 0
    for i in 0..(num_of_inputs_VAL-1):
        default_vals[i] = 0.0
        min_vals[i] = RANDOM_FLOAT
        max_vals[i] = RANDOM_FLOAT

    var statement_counter = 0

    #This is for the inputs 1, "freq" case. (where "freq" is not viewed as varargs)
    #input 2, "freq", "stmt" is covered in the other macro
    if param_names_kind == nnkStrLit or param_names_kind == nnkIdent:
        let param_name = param_names.strVal()
        
        checkValidParamName(param_name)
        
        param_names_string.add($param_name & ",")
        statement_counter = 1

    #block case
    else:
        #multiple statements: "freq" {440} OR "freq" {0, 22000} OR "freq" {0 22000} OR "freq" {440, 0, 22000} OR "freq" {440 0 22000}
        if param_names_kind == nnkStmtList:
            for statement in param_names.children():
                let statement_kind = statement.kind

                #"freq" / freq
                if statement_kind == nnkStrLit or statement_kind == nnkIdent:
                    let param_name = statement.strVal()

                    #Buffer without param name ????
                    #if param_name == "Buffer":

                    checkValidParamName(param_name)
                    
                    param_names_string.add($param_name & ",")
                
                #"freq" {440, 0, 22000} OR "freq" {440 0 22000}
                elif statement_kind == nnkCommand:
                    assert statement.len == 2

                    #The name of the param
                    let 
                        param_name_node = statement[0]
                        param_name_node_kind = param_name_node.kind
                    if param_name_node_kind != nnkStrLit and param_name_node_kind != nnkIdent:
                        error("Expected input name number " & $(statement_counter + 1) & " to be either an identifier or a string literal value")

                    let param_name = param_name_node.strVal()
                    checkValidParamName(param_name)

                    param_names_string.add($param_name & ",")
                
                    #The list of { } or Buffer
                    let default_min_max = statement[1]

                    var 
                        default_val : float
                        min_val : float
                        max_val : float

                    #Ident, no curly brackets Buffer
                    if default_min_max.kind == nnkIdent:
                        if default_min_max.strVal == "Buffer":
                            min_val = BUFFER_FLOAT
                            max_val = BUFFER_FLOAT
                    
                    elif default_min_max.kind == nnkCurly:
                        (default_val, min_val, max_val) = extractDefaultMinMax(default_min_max, param_name)
                    else:
                        error("Expected default / min / max values for \"" & $param_name & "\" to be wrapped in curly brackets, or 'Buffer' to be declared.")

                    default_vals[statement_counter] = default_val
                    min_vals[statement_counter] = min_val
                    max_vals[statement_counter] = max_val
                
                #Just {0, 0, 1} / {0 0 1}, no param name provided!
                elif statement_kind == nnkCurly:
                    let param_name = "in" & $(statement_counter+1)
                    
                    param_names_string.add($param_name & ",")

                    let (default_val, min_val, max_val) = extractDefaultMinMax(statement, param_name)
                    
                    default_vals[statement_counter] = default_val
                    min_vals[statement_counter] = min_val
                    max_vals[statement_counter] = max_val

                statement_counter += 1
                    
        #Single "freq" {440, 0, 22000} OR "freq" on same line: ins 1, "freq" {440, 0, 22000}
        elif param_names_kind == nnkCommand:
            error("ins: syntax not implemented yet")

    #inputs count mismatch
    if param_names_kind == nnkNilLit:
        for i in 0..num_of_inputs_VAL-1:
            param_names_string.add("in" & $(i + 1) & ",")
    else:
        if statement_counter != num_of_inputs_VAL:
            error("Expected " & $num_of_inputs_VAL & " input names, got " & $statement_counter)

    #Remove trailing coma
    if param_names_string.len > 1:
        param_names_string = param_names_string[0..param_names_string.high-1]

    #Assign to node
    param_names_node = newLit(param_names_string)

    let defaults_mins_maxs = buildDefaultMinMaxArrays(num_of_inputs_VAL, default_vals, min_vals, max_vals)

    return quote do:
        #Export to C: inline all functions
        when defined(omni_export_c):
            {.pragma: omni_export_or_dynlib, inline.}

        #shared / static lib: needs dynlib for export the symbol
        else:
            {.pragma: omni_export_or_dynlib, dynlib.}
            
        const 
            omni_inputs            {.inject.} = `num_of_inputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to insert variable from macro's scope
            omni_input_names_const {.inject.} = `param_names_node`  #It's possible to insert NimNodes directly in the code block 

        let omni_input_names_let   {.inject.} = `param_names_node`

        #compile time variable if ins are defined
        let declared_inputs {.inject, compileTime.} = true

        #const statement for defaults / mins / maxs
        `defaults_mins_maxs`
        
        #Generate procs for min/max
        generate_inputs_templates(`num_of_inputs_VAL`, 0, 1)

        generate_args_templates(`num_of_inputs_VAL`)

        proc get_dynamic_input[T : CFloatPtrPtr or CDoublePtrPtr; Y : SomeNumber](ins_Nim : T, chan : Y, audio_index_loop : int = 0) : float =
            let chan_int = int(chan)
            if chan_int < omni_inputs:
                return float(ins_Nim[chan_int][audio_index_loop])
            else:
                return 0.0
        
        #Export to C
        proc Omni_UGenInputs() : int32 {.exportc: "Omni_UGenInputs", omni_export_or_dynlib.} =
            return int32(omni_inputs)

        proc Omni_UGenInputNames() : ptr cchar {.exportc: "Omni_UGenInputNames", omni_export_or_dynlib.} =
            return cast[ptr cchar](unsafeAddr(omni_input_names_let[0]))

        proc Omni_UGenDefaults() : ptr cfloat {.exportc: "Omni_UGenDefaults", omni_export_or_dynlib.} =
            return cast[ptr cfloat](omni_defaults_let.unsafeAddr)

macro inputs*(num_of_inputs : typed, param_names : untyped = nil) : untyped =
    return quote do:
        ins(`num_of_inputs`, `param_names`)

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
    elif num_of_outputs_VAL > omni_max_inputs_outputs_const:
        error("Exceeded maximum number of outputs, " & $omni_max_inputs_outputs_const)

    var statement_counter = 0

    #This is for the outputs 1, "freq" case... output 2, "freq", "stmt" is covered in the other macro
    if param_names_kind == nnkStrLit or param_names_kind == nnkIdent:
        let param_name = param_names.strVal()
        
        for individualChar in param_name:
            if not (individualChar in acceptedCharsForParamName):
                error("Invalid character " & $individualChar & $ " in output name " & $param_name)
        
        param_names_string.add($param_name & ",")
        statement_counter = 1

    #Normal block case
    else:
        for statement in param_names.children():
            let statement_kind = statement.kind

            if statement_kind != nnkStrLit and statement_kind != nnkIdent:
                error("Expected output name number " & $(statement_counter + 1) & " to be either an identifier or a string literal value")
        
            let param_name = statement.strVal()

            checkValidParamName(param_name)
            
            param_names_string.add($param_name & ",")
            statement_counter += 1
    
    #No outs specified
    if param_names_kind == nnkNilLit:
        for i in 0..num_of_outputs_VAL-1:
            param_names_string.add("out" & $(i + 1) & ",")
    else:
        if statement_counter != num_of_outputs_VAL:
            error("Expected " & $num_of_outputs_VAL & " input names, got " & $statement_counter)
    
    #Remove trailing coma
    if param_names_string.len > 1:
        param_names_string = param_names_string[0..param_names_string.high-1]

    #Assign to node
    param_names_node = newLit(param_names_string)

    return quote do: 
        const 
            omni_outputs            {.inject.} = `num_of_outputs_VAL` #{.inject.} acts just like Julia's esc(). backticks to outsert variable from macro's scope
            omni_output_names_const {.inject.} = `param_names_node`  #It's possible to outsert NimNodes directly in the code block 
        
        let omni_output_names_let   {.inject.} = `param_names_node`

        #compile time variable if outs are defined
        let declared_outputs {.inject, compileTime.} = true
        
        #generate_outputs_templates(`num_of_outputs_VAL`)
        
        #Export to C
        proc Omni_UGenOutputs() : int32 {.exportc: "Omni_UGenOutputs", omni_export_or_dynlib.} =
            return int32(omni_outputs)

        proc Omni_UGenOutputNames() : ptr cchar {.exportc: "Omni_UGenOutputNames", omni_export_or_dynlib.} =
            return cast[ptr cchar](unsafeAddr(omni_output_names_let[0]))

macro outputs*(num_of_outputs : typed, param_names : untyped = nil) : untyped  =
    return quote do:
        outs(`num_of_outputs`, `param_names`)