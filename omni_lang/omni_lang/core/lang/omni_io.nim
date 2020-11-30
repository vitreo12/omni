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

const acceptedCharsForParamName* = {'a'..'z', 'A'..'Z', '0'..'9', '_'}

#default name when not specifying default buffer value
const OMNI_DEFAULT_NIL_BUFFER = "OMNI_DEFAULT_NIL_BUFFER"

#Compile time arrays for params code generation
var
    params_names_list*    {.compileTime.} : seq[string]
    params_defaults_list* {.compileTime.} : seq[float]

var
    buffers_names_list*   {.compileTime.} : seq[string]

#Compile time array of buffers to unpack
var 
    at_least_one_buffer*  {.compileTime.} = false
    #ins_buffers_list*     {.compileTime.} : seq[string]
    #params_buffers_list*  {.compileTime.} : seq[string]

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

    let buffer_fatal = nnkWhenStmt.newTree(
        nnkElifBranch.newTree(
            nnkCall.newTree(
                newIdentNode("declared"),
                newIdentNode(in_num & "_buffer")
            ),
            nnkStmtList.newTree(
                nnkPragma.newTree(
                    nnkExprColonExpr.newTree(
                        newIdentNode("fatal"),
                        newLit("Can\'t access " & in_num & ", it\'s a Buffer input.")
                    )
                )
            )
        )
    )

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
                        buffer_fatal,
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
                        buffer_fatal,
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

    let buffer_fatal = nnkWhenStmt.newTree(
        nnkElifBranch.newTree(
            nnkCall.newTree(
                newIdentNode("declared"),
                newIdentNode(in_num & "_buffer")
            ),
            nnkStmtList.newTree(
                nnkPragma.newTree(
                    nnkExprColonExpr.newTree(
                        newIdentNode("fatal"),
                        newLit("Can\'t access " & in_num & ", it\'s a Buffer input.")
                    )
                )
            )
        )
    )

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
                        buffer_fatal,
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
                        buffer_fatal,
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

        elif value_kind == nnkIdent:
            if value.strVal == "Buffer":
                return (0.0, BUFFER_FLOAT, BUFFER_FLOAT)
            else:
                error("Invalid syntax for input \"" & $param_name & "\"")

        else:
            error("Invalid syntax for input \"" & $param_name & "\"")

    return (default_num, min_num, max_num)

proc build_default_min_max_arrays(num_of_inputs : int, default_vals : seq[float32], min_vals : seq[float], max_vals : seq[float], ins_names_string : string, ins_or_params : bool = false) : NimNode {.compileTime.} =
    let default_vals_len = default_vals.len()

    #Find mismatch. Perhaps user hasn't defined def/min/max for some params
    if num_of_inputs != default_vals_len:
        error("ins: Got " & $num_of_inputs & " number of inputs but only " & $default_vals_len & " default / min / max values.")

    result = nnkStmtList.newTree()

    var 
        in_or_param = "in"
        input_or_param = "input"

    if ins_or_params == true:
        in_or_param = "param"
        input_or_param = "param"

    #Get the ins names as a seq to be indexed
    var ins_names_seq = ins_names_string.split(',')
    
    var 
        default_min_max_const_section = nnkConstSection.newTree()
        defaults_array_let_section = nnkLetSection.newTree()
        defaults_array_const = nnkConstDef.newTree(
            nnkPragmaExpr.newTree(
                newIdentNode("omni_" & input_or_param & "_defaults_const"),
                nnkPragma.newTree(
                    newIdentNode("inject")
                )
            ),
            newEmptyNode()
        )
        defaults_array_let = nnkIdentDefs.newTree(
            nnkPragmaExpr.newTree(
                newIdentNode("omni_" & input_or_param & "_defaults_let"),
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
        defaults_array_bracket.add(
            newLit(default_val)
        )

        #param
        if ins_or_params:
            params_defaults_list.add(default_val)

        #Don't generate min max for param (will be calculated later)
        if not ins_or_params:
            if min_val != RANDOM_FLOAT and min_val != BUFFER_FLOAT:
                default_min_max_const_section.add(
                    nnkConstDef.newTree(
                        nnkPragmaExpr.newTree(
                            newIdentNode(in_or_param & $(i_plus_one) & "_min"),
                            nnkPragma.newTree(
                                newIdentNode("inject")
                            )
                        ),
                        newEmptyNode(),
                        newLit(min_val)
                    )
                )

            if max_val != RANDOM_FLOAT and max_val != BUFFER_FLOAT:
                default_min_max_const_section.add(
                    nnkConstDef.newTree(
                        nnkPragmaExpr.newTree(
                            newIdentNode(in_or_param & $(i_plus_one) & "_max"),
                            nnkPragma.newTree(
                                newIdentNode("inject")
                            )
                        ),
                        newEmptyNode(),
                        newLit(max_val)
                    )
                )

    defaults_array_const.add(defaults_array_bracket)
    default_min_max_const_section.add(defaults_array_const)

    defaults_array_let.add(defaults_array_bracket)
    defaults_array_let_section.add(defaults_array_let)

    #Declare min max as const, the array as both const (for static IO at the end of perform) and let (so i can get its memory address for Omni_UGenDefaults())
    result.add(default_min_max_const_section)
    result.add(defaults_array_let_section)

macro ins_inner*(ins_number : typed, ins_names : untyped = nil) : untyped =
    var 
        ins_number_VAL : int
        ins_names_string : string = ""
        ins_names_node : NimNode

        default_vals : seq[float32]
        min_vals     : seq[float]
        max_vals     : seq[float]

    let ins_names_kind = ins_names.kind

    #Must be an int literal OR nnkStmtListExpr (for ins: 1)
    if ins_number.kind == nnkIntLit: 
        ins_number_VAL = int(ins_number.intVal)     
    elif ins_number.kind == nnkStmtListExpr:
        ins_number_VAL = int(ins_number[0].intVal)    
    else:
        error("ins: Expected the number of inputs to be expressed as an integer literal value")

    if ins_names_kind != nnkStmtList and ins_names_kind != nnkStrLit and ins_names_kind != nnkCommand and ins_names_kind != nnkNilLit:
        error("ins: Expected a block statement after the number of inputs")

    #Always have at least one input
    if ins_number_VAL == 0:
        ins_number_VAL = 1
    elif ins_number_VAL < 0:
        error("ins: Expected a positive number for inputs number")
    elif ins_number_VAL > omni_max_inputs_outputs_const:
        error("ins: Exceeded maximum number of inputs, " & $omni_max_inputs_outputs_const)

    #init the seqs
    default_vals = newSeq[float32](ins_number_VAL)
    min_vals     = newSeq[float](ins_number_VAL)
    max_vals     = newSeq[float](ins_number_VAL)

    #Fill them with a random float, but keep default's one to 0
    for i in 0..(ins_number_VAL-1):
        default_vals[i] = 0.0
        min_vals[i] = RANDOM_FLOAT
        max_vals[i] = RANDOM_FLOAT

    var statement_counter = 0

    #This is for the inputs 1, "freq" case. (where "freq" is not viewed as varargs)
    #input 2, "freq", "stmt" is covered in the other macro
    if ins_names_kind == nnkStrLit or ins_names_kind == nnkIdent:
        let param_name = ins_names.strVal()
        
        checkValidParamName(param_name)
        
        ins_names_string.add($param_name & ",")
        statement_counter = 1

    #block case
    else:
        #multiple statements: "freq" {440} OR "freq" {0, 22000} OR "freq" {0 22000} OR "freq" {440, 0, 22000} OR "freq" {440 0 22000}
        if ins_names_kind == nnkStmtList:
            for statement in ins_names.children():
                let statement_kind = statement.kind

                #"freq" / freq
                if statement_kind == nnkStrLit or statement_kind == nnkIdent:
                    let param_name = statement.strVal()

                    #Buffer without param name ????
                    #if param_name == "Buffer":

                    checkValidParamName(param_name)
                    
                    ins_names_string.add($param_name & ",")
                
                #"freq" {440, 0, 22000} OR "freq" {440 0 22000}
                elif statement_kind == nnkCommand:
                    assert statement.len == 2

                    #The name of the param
                    let 
                        param_name_node = statement[0]
                        param_name_node_kind = param_name_node.kind
                    if param_name_node_kind != nnkStrLit and param_name_node_kind != nnkIdent:
                        error("ins: Expected input name number " & $(statement_counter + 1) & " to be either an identifier or a string literal value")

                    let param_name = param_name_node.strVal()
                    checkValidParamName(param_name)

                    ins_names_string.add($param_name & ",")
                
                    #The list of { } or Buffer
                    let 
                        default_min_max = statement[1]
                        default_min_max_kind = default_min_max.kind

                    var 
                        default_val : float
                        min_val : float
                        max_val : float

                    #Ident, no curly brackets Buffer
                    if default_min_max_kind == nnkIdent:
                        if default_min_max.strVal == "Buffer":
                            min_val = BUFFER_FLOAT
                            max_val = BUFFER_FLOAT     
                    elif default_min_max_kind == nnkCurly:
                        (default_val, min_val, max_val) = extractDefaultMinMax(default_min_max, param_name)

                    #single number literal: wrap in curly brackets
                    elif default_min_max_kind == nnkIntLit or default_min_max_kind == nnkFloatLit:
                        let default_min_max_curly = nnkCurly.newTree(default_min_max)
                        (default_val, min_val, max_val) = extractDefaultMinMax(default_min_max_curly, param_name)
                    else:
                        error("ins: Expected default / min / max values for \"" & $param_name & "\" to be wrapped in curly brackets, or 'Buffer' to be declared.")

                    default_vals[statement_counter] = default_val
                    min_vals[statement_counter] = min_val
                    max_vals[statement_counter] = max_val
                
                #Just {0, 0, 1} / {0 0 1}, no param name provided!
                elif statement_kind == nnkCurly:
                    let param_name = "in" & $(statement_counter+1)
                    
                    ins_names_string.add($param_name & ",")

                    let (default_val, min_val, max_val) = extractDefaultMinMax(statement, param_name)
                    
                    default_vals[statement_counter] = default_val
                    min_vals[statement_counter] = min_val
                    max_vals[statement_counter] = max_val

                else:
                    error("ins: Invalid syntax: '" & $(repr(statement)) & "'")

                statement_counter += 1
                    
        #Single "freq" {440, 0, 22000} OR "freq" on same line: ins 1, "freq" {440, 0, 22000}
        elif ins_names_kind == nnkCommand:
            error("ins: syntax not implemented yet")

    #inputs count mismatch
    if ins_names_kind == nnkNilLit:
        for i in 0..ins_number_VAL-1:
            ins_names_string.add("in" & $(i + 1) & ",")
    else:
        if statement_counter != ins_number_VAL:
            error("ins: Expected " & $ins_number_VAL & " input names, got " & $statement_counter)

    #Remove trailing coma
    if ins_names_string.len > 1:
        ins_names_string = ins_names_string[0..ins_names_string.high-1]

    #Assign to node
    ins_names_node = newLit(ins_names_string)

    let defaults_mins_maxs = build_default_min_max_arrays(ins_number_VAL, default_vals, min_vals, max_vals, ins_names_string)

    return quote do:
        when not declared(declared_inputs):
            const 
                omni_inputs            {.inject.} = `ins_number_VAL`  
                omni_input_names_const {.inject.} = `ins_names_node`  #Used for IO.txt

            let omni_input_names_let   {.inject.} = `ins_names_node`  #Used as global in C export

            #compile time variable if ins are defined
            let declared_inputs {.inject, compileTime.} = true

            #const statement for defaults / mins / maxs
            `defaults_mins_maxs`
            
            #Generate procs for min/max
            generate_inputs_templates(`ins_number_VAL`, 0, 1)

            #Generate arg aliases for in
            generate_args_templates(`ins_number_VAL`)

            #For in[i] access
            proc get_dynamic_input[T : CFloatPtrPtr or CDoublePtrPtr; Y : SomeNumber](ins_Nim : T, chan : Y, audio_index_loop : int = 0) : float =
                let chan_int = int(chan)
                if chan_int < omni_inputs:
                    return float(ins_Nim[chan_int][audio_index_loop])
                else:
                    return 0.0
            
            #Export to C
            proc Omni_UGenInputs() : int32 {.exportc: "Omni_UGenInputs", dynlib.} =
                return int32(omni_inputs)

            proc Omni_UGenInputNames() : ptr cchar {.exportc: "Omni_UGenInputNames", dynlib.} =
                return cast[ptr cchar](unsafeAddr(omni_input_names_let[0]))

            proc Omni_UGenInputDefaults() : ptr cfloat {.exportc: "Omni_UGenInputDefaults", dynlib.} =
                return cast[ptr cfloat](omni_input_defaults_let.unsafeAddr)
        else:
            {.fatal: "ins: Already defined once.".}

macro ins*(args : varargs[untyped]) : untyped =
    var 
        ins_number : int
        ins_names  : NimNode

    let args_first = args[0]

    # ins 1 
    # ins: ... (dynamic counting)
    if args.len == 1:
        if args_first.kind == nnkIntLit:
            ins_number = int(args_first.intVal)
        elif args_first.kind == nnkStmtList:
            ins_names = args_first
            ins_number = ins_names.len
        else:
            error("ins: invalid syntax: '" & repr(args) & "'. It must either be an integer literal or a statement list.")
    
    # ins 1: ...
    elif args.len == 2:
        if args_first.kind == nnkIntLit:
            ins_number = int(args_first.intVal)
            let args_second = args[1]
            if args_second.kind == nnkStmtList:
                ins_names = args_second
            else:
                error("ins: invalid statement list: '" & repr(args_second) & "'.")
        else:
            error("ins: invalid first argument: '" & repr(args_first) & "'. First entry must be an integer literal.")

    else:
        error("ins: invalid syntax: '" & repr(args) & "'. Too many arguments.")

    return quote do:
        ins_inner(`ins_number`, `ins_names`)

macro inputs*(args : varargs[untyped]) : untyped =
    return quote do:
        ins(args)

#outs
macro outs_inner*(outs_number : typed, outs_names : untyped = nil) : untyped =
    var 
        outs_number_VAL : int
        outs_names_string : string = ""
        outs_names_node : NimNode

    let outs_names_kind = outs_names.kind

    #Must be an int literal OR nnkStmtListExpr (for ins: 1)
    if outs_number.kind == nnkIntLit: 
        outs_number_VAL = int(outs_number.intVal)     
    elif outs_number.kind == nnkStmtListExpr:
        outs_number_VAL = int(outs_number[0].intVal)    
    else:
        error("outs: Expected the number of outputs to be expressed as an integer literal value")

    if outs_names_kind != nnkStmtList and outs_names_kind != nnkStrLit and outs_names_kind != nnkCommand and outs_names_kind != nnkNilLit:
        error("outs: Expected a block statement after the number of outputs")

    #Always have at least one output
    if outs_number_VAL == 0:
        outs_number_VAL = 1
    elif outs_number_VAL < 0:
        error("outs: Expected a positive number for outputs number")
    elif outs_number_VAL > omni_max_inputs_outputs_const:
        error("outs: Exceeded maximum number of outputs, " & $omni_max_inputs_outputs_const)

    var statement_counter = 0

    #This is for the outputs 1, "freq" case... output 2, "freq", "stmt" is covered in the other macro
    if outs_names_kind == nnkStrLit or outs_names_kind == nnkIdent:
        let param_name = outs_names.strVal()
        
        for individualChar in param_name:
            if not (individualChar in acceptedCharsForParamName):
                error("outs: Invalid character " & $individualChar & $ " in output name " & $param_name)
        
        outs_names_string.add($param_name & ",")
        statement_counter = 1

    #Normal block case
    else:
        for statement in outs_names.children():
            let statement_kind = statement.kind

            if statement_kind != nnkStrLit and statement_kind != nnkIdent:
                error("outs: Expected output name number " & $(statement_counter + 1) & " to be either an identifier or a string literal value")
        
            let param_name = statement.strVal()

            checkValidParamName(param_name)
            
            outs_names_string.add($param_name & ",")
            statement_counter += 1
    
    #No outs specified
    if outs_names_kind == nnkNilLit:
        for i in 0..outs_number_VAL-1:
            outs_names_string.add("out" & $(i + 1) & ",")
    else:
        if statement_counter != outs_number_VAL:
            error("outs: Expected " & $outs_number_VAL & " input names, got " & $statement_counter)
    
    #Remove trailing coma
    if outs_names_string.len > 1:
        outs_names_string = outs_names_string[0..outs_names_string.high-1]

    #Assign to node
    outs_names_node = newLit(outs_names_string)

    return quote do: 
        when not declared(declared_outputs):
            const 
                omni_outputs            {.inject.} = `outs_number_VAL` 
                omni_output_names_const {.inject.} = `outs_names_node` #Used for IO.txt
            
            let omni_output_names_let   {.inject.} = `outs_names_node` #Used as global in C export

            #compile time variable if outs are defined
            let declared_outputs {.inject, compileTime.} = true
            
            #generate_outputs_templates(`outs_number_VAL`)
            
            #Export to C
            proc Omni_UGenOutputs() : int32 {.exportc: "Omni_UGenOutputs", dynlib.} =
                return int32(omni_outputs)

            proc Omni_UGenOutputNames() : ptr cchar {.exportc: "Omni_UGenOutputNames", dynlib.} =
                return cast[ptr cchar](unsafeAddr(omni_output_names_let[0]))
        else:
            {.fatal: "outs: Already defined once.".}

macro outs*(args : varargs[untyped]) : untyped =
    var 
        outs_number : int
        outs_names  : NimNode

    let args_first = args[0]

    # outs 1 
    # outs: ... (dynamic counting)
    if args.len == 1:
        if args_first.kind == nnkIntLit:
            outs_number = int(args_first.intVal)
        elif args_first.kind == nnkStmtList:
            outs_names = args_first
            outs_number = outs_names.len
        else:
            error("outs: invalid syntax: '" & repr(args) & "'. It must either be an integer literal or a statement list.")
    
    # outs 1: ...
    elif args.len == 2:
        if args_first.kind == nnkIntLit:
            outs_number = int(args_first.intVal)
            let args_second = args[1]
            if args_second.kind == nnkStmtList:
                outs_names = args_second
            else:
                error("outs: invalid statement list: '" & repr(args_second) & "'.")
        else:
            error("outs: invalid first argument: '" & repr(args_first) & "'. First entry must be an integer literal.")

    else:
        error("outs: invalid syntax: '" & repr(args) & "'. Too many arguments.")

    return quote do:
        outs_inner(`outs_number`, `outs_names`)

macro outputs*(args : varargs[untyped]) : untyped =
    return quote do:
        outs(args)

#params

#Returns a template that generates all set procs, including setParam
proc params_generate_set_templates(min_vals : seq[float], max_vals : seq[float]) : NimNode {.compileTime.} =
    var
        setParam_if = nnkIfStmt.newTree()
        setParam_block = nnkStmtList.newTree(setParam_if)
        setParam = nnkProcDef.newTree(
            newIdentNode("Omni_UGenSetParam"),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("void"),
            nnkIdentDefs.newTree(
                newIdentNode("ugen"),
                nnkPtrTy.newTree(
                    newIdentNode("UGen")
                ),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("param"),
                newIdentNode("cstring"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("val"),
                newIdentNode("float"),
                newEmptyNode()
            )
            ),
            nnkPragma.newTree(
                newIdentNode("exportc"),
                newIdentNode("dynlib")
            ),
            newEmptyNode(),
            setParam_block
        )

    let 
        final_template_block = nnkStmtList.newTree()
        final_template = nnkTemplateDef.newTree(
            newIdentNode("generate_params_procs"),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("untyped")
            ),
            nnkPragma.newTree(
                newIdentNode("dirty")
            ),
            newEmptyNode(),
            final_template_block
        )

    result = nnkStmtList.newTree(
        final_template
    )

    if params_names_list.len > 0:
        for i, param_name in params_names_list:
            var 
                omni_ugen_setparam_func_name = newIdentNode("Omni_UGenSetParam_" & param_name)

                set_param_spin = nnkCall.newTree(
                    nnkDotExpr.newTree(
                        nnkDotExpr.newTree(
                            newIdentNode("ugen"),
                            newIdentNode("params_lock")
                        ),
                        newIdentNode("spin")
                    )
                )

                set_param_func_block = nnkStmtList.newTree(
                    set_param_spin
                )

                set_param_func = nnkProcDef.newTree(
                    omni_ugen_setparam_func_name,
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("void"),
                        nnkIdentDefs.newTree(
                            newIdentNode("ugen"),
                            nnkPtrTy.newTree(
                                newIdentNode("UGen")
                            ),
                            newEmptyNode()
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("val"),
                            newIdentNode("float"),
                            newEmptyNode()
                        )
                    ),
                    nnkPragma.newTree(
                        newIdentNode("exportc"),
                        newIdentNode("dynlib")
                    ),
                    newEmptyNode(),
                    set_param_func_block
                )

            let 
                min_val = min_vals[i]
                max_val = max_vals[i]

            var 
                set_min_val = false
                set_max_val = false

            #if valid min_val, use it
            if min_val != RANDOM_FLOAT and min_val != BUFFER_FLOAT:
                let 
                    min_val_lit = newFloatLitNode(min_val)
                    
                    min_val_assgn = nnkAsgn.newTree(
                        nnkDotExpr.newTree(
                            newIdentNode("ugen"),
                            newIdentNode("freq_param")
                        ),
                        min_val_lit
                    )
                    
                    min_val_elif_branch = nnkElifBranch.newTree(
                        nnkInfix.newTree(
                            newIdentNode("<"),
                            newIdentNode("val"),
                            min_val_lit,
                        ),
                        nnkStmtList.newTree(
                            min_val_assgn
                        )
                    )
                
                set_param_spin.add(
                    nnkIfStmt.newTree(
                        min_val_elif_branch
                    )
                )

                #keep adding to the if statement
                set_param_spin = set_param_spin[^1]

                set_min_val = true

            #if valid max val, use it
            if max_val != RANDOM_FLOAT and min_val != BUFFER_FLOAT:
                let 
                    max_val_lit = newFloatLitNode(max_val)
                    
                    max_val_assgn = nnkAsgn.newTree(
                        nnkDotExpr.newTree(
                            newIdentNode("ugen"),
                            newIdentNode("freq_param")
                        ),
                        max_val_lit
                    )
                    
                    max_val_elif_branch = nnkElifBranch.newTree(
                        nnkInfix.newTree(
                            newIdentNode(">"),
                            newIdentNode("val"),
                            max_val_lit,
                        ),
                        nnkStmtList.newTree(
                            max_val_assgn
                        )
                    )

                #elif (continue from min_val)
                if set_min_val:
                    set_param_spin.add(
                        max_val_elif_branch
                    )

                #if (no min_val specified)
                else:
                    set_param_spin.add(
                        nnkIfStmt.newTree(
                            max_val_elif_branch
                        )
                    )

                    #Keep adding to the if statement
                    set_param_spin = set_param_spin[^1]
                
                set_max_val = true

            let val_assgn = nnkAsgn.newTree(
                nnkDotExpr.newTree(
                    newIdentNode("ugen"),
                    newIdentNode(param_name & "_param")
                ),
                newIdentNode("val")
            )

            #Else
            if set_min_val or set_max_val:
                set_param_spin.add(
                    nnkElse.newTree(
                        val_assgn
                    )
                )
            
            #Assign directly
            else:
                set_param_spin.add(
                    val_assgn
                )

            final_template_block.add(
                set_param_func
            )

            setParam_if.add(
                nnkElifBranch.newTree(
                    nnkInfix.newTree(
                        newIdentNode("=="),
                        newIdentNode("param"),
                        newLit(param_name)
                    ),
                    nnkStmtList.newTree(
                        nnkCall.newTree(
                            omni_ugen_setparam_func_name,
                            newIdentNode("ugen"),
                            newIdentNode("val")
                        )
                    )
                )
            )
        
        setParam_if.add(
            nnkElse.newTree(
                nnkStmtList.newTree(
                    nnkCall.newTree(
                        newIdentNode("omni_print"),
                        newLit("ERROR: Omni_UGenSetParam: invalid param name")
                    )
                )
            )
        )

    else:
        setParam_block[0] = nnkDiscardStmt.newTree(
            newEmptyNode()
        )

    final_template_block.add(
        setParam
    )

    #error repr result

#Returns a template that unpacks params for perform block
proc params_generate_unpack_templates() : NimNode {.compileTime.} =
    var 
        init_block = nnkStmtList.newTree()
        unpack_params_init = nnkTemplateDef.newTree(
            newIdentNode("unpack_params_init"),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("untyped")
            ),
            nnkPragma.newTree(
                newIdentNode("dirty")
            ),
            newEmptyNode(),
            init_block
        )
        pre_init_block = nnkStmtList.newTree()
        unpack_params_pre_init = nnkTemplateDef.newTree(
            newIdentNode("unpack_params_pre_init"),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("untyped")
            ),
            nnkPragma.newTree(
                newIdentNode("dirty")
            ),
            newEmptyNode(),
            pre_init_block
        )
        perform_block = nnkStmtList.newTree()
        unpack_params_perform = nnkTemplateDef.newTree(
            newIdentNode("unpack_params_perform"),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("untyped")
            ),
            nnkPragma.newTree(
                newIdentNode("dirty")
            ),
            newEmptyNode(),
            perform_block
        )

    result = nnkStmtList.newTree(
        unpack_params_init,
        unpack_params_pre_init,
        unpack_params_perform
    )

    if params_names_list.len > 0:
        var 
            unpack_init = nnkStmtList.newTree()
            unpack_pre_init = nnkStmtList.newTree()
            unpack_perform = nnkStmtList.newTree()

        init_block.add(
            nnkCall.newTree(
                nnkDotExpr.newTree(
                nnkDotExpr.newTree(
                    newIdentNode("ugen"),
                    newIdentNode("params_lock")
                ),
                newIdentNode("spin")
                ),
                unpack_init
            )
        )

        pre_init_block.add(
            unpack_pre_init
        )

        perform_block.add(
            nnkCall.newTree(
                nnkDotExpr.newTree(
                nnkDotExpr.newTree(
                    newIdentNode("ugen"),
                    newIdentNode("params_lock")
                ),
                newIdentNode("spin")
                ),
                unpack_perform
            )
        )

        for i, param_name in params_names_list:
            let param_name_param = newIdentNode(param_name & "_param")
            
            unpack_init.add(
                nnkAsgn.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("ugen"),
                        param_name_param
                    ),
                    newLit(
                        params_defaults_list[i]
                    )
                ),

                nnkLetSection.newTree(
                    nnkIdentDefs.newTree(
                        newIdentNode(param_name),
                        newEmptyNode(),
                        nnkDotExpr.newTree(
                            newIdentNode("ugen"),
                            param_name_param
                        )
                    )
                )
            )

            unpack_pre_init.add(
                nnkLetSection.newTree(
                    nnkIdentDefs.newTree(
                        newIdentNode(param_name),
                        newEmptyNode(),
                        newLit(0)
                    )
                )
            )

            unpack_perform.add(
                nnkLetSection.newTree(
                    nnkIdentDefs.newTree(
                        newIdentNode(param_name),
                        newEmptyNode(),
                        nnkDotExpr.newTree(
                            newIdentNode("ugen"),
                            param_name_param
                        )
                    )
                )
            )
    else:
        init_block.add(
            nnkDiscardStmt.newTree(
                newEmptyNode()
            )
        )

        pre_init_block.add(
            nnkDiscardStmt.newTree(
                newEmptyNode()
            )
        )

        perform_block.add(
            nnkDiscardStmt.newTree(
                newEmptyNode()
            )
        )

macro params_inner*(params_number : typed, params_names : untyped) : untyped =
    var 
        params_number_VAL : int
        params_names_string : string = ""
        params_names_node : NimNode

        default_vals : seq[float32]
        min_vals     : seq[float]
        max_vals     : seq[float]

    let params_names_kind = params_names.kind

    #Must be an int literal OR nnkStmtListExpr (for params: 1)
    if params_number.kind == nnkIntLit: 
        params_number_VAL = int(params_number.intVal)     
    elif params_number.kind == nnkStmtListExpr:
        params_number_VAL = int(params_number[0].intVal)    
    else:
        error("params: Expected the number of params to be expressed as an integer literal value")

    if params_names_kind != nnkStmtList and params_names_kind != nnkStrLit and params_names_kind != nnkCommand and params_names_kind != nnkNilLit:
        error("params: Expected a block statement after the number of params")

    var zero_params = false
    
    if params_number_VAL == 0:
        params_number_VAL = 1
        zero_params = true
    elif params_number_VAL < 0:
        error("params: Expected a positive number for params number")

    #init the seqs
    default_vals = newSeq[float32](params_number_VAL)
    min_vals     = newSeq[float](params_number_VAL)
    max_vals     = newSeq[float](params_number_VAL)

    #Fill them with a random float, but keep default's one to 0
    for i in 0..(params_number_VAL-1):
        default_vals[i] = 0.0
        min_vals[i] = RANDOM_FLOAT
        max_vals[i] = RANDOM_FLOAT

    var statement_counter = 0

    #This is for the params 1, "freq" case. (where "freq" is not viewed as varargs)
    #param 2, "freq", "stmt" is covered in the other macro
    if params_names_kind == nnkStrLit or params_names_kind == nnkIdent:
        let param_name = params_names.strVal()
        
        checkValidParamName(param_name)
        
        params_names_string.add($param_name & ",")
        statement_counter = 1

    #block case
    else:
        #multiple statements: "freq" {440} OR "freq" {0, 22000} OR "freq" {0 22000} OR "freq" {440, 0, 22000} OR "freq" {440 0 22000}
        if params_names_kind == nnkStmtList:
            for statement in params_names.children():
                let statement_kind = statement.kind

                #"freq" / freq
                if statement_kind == nnkStrLit or statement_kind == nnkIdent:
                    let param_name = statement.strVal()

                    checkValidParamName(param_name)
                    
                    params_names_string.add($param_name & ",")
                    params_names_list.add(param_name)
                
                #"freq" {440, 0, 22000} OR "freq" {440 0 22000}
                elif statement_kind == nnkCommand:
                    assert statement.len == 2

                    #The name of the param
                    let 
                        param_name_node = statement[0]
                        param_name_node_kind = param_name_node.kind
                    if param_name_node_kind != nnkStrLit and param_name_node_kind != nnkIdent:
                        error("params: Expected param name number " & $(statement_counter + 1) & " to be either an identifier or a string literal value")

                    let param_name = param_name_node.strVal()
                    checkValidParamName(param_name)

                    params_names_string.add($param_name & ",")
                    params_names_list.add(param_name)
                
                    #The list of { } or Buffer
                    let 
                        default_min_max = statement[1]
                        default_min_max_kind = default_min_max.kind

                    var 
                        default_val : float
                        min_val : float
                        max_val : float

                    #Ident, no curly brackets Buffer
                    if default_min_max_kind == nnkIdent:
                        if default_min_max.strVal == "Buffer":
                            min_val = BUFFER_FLOAT
                            max_val = BUFFER_FLOAT     
                    elif default_min_max_kind == nnkCurly:
                        (default_val, min_val, max_val) = extractDefaultMinMax(default_min_max, param_name)

                    #single number literal: wrap in curly brackets
                    elif default_min_max_kind == nnkIntLit or default_min_max_kind == nnkFloatLit:
                        let default_min_max_curly = nnkCurly.newTree(default_min_max)
                        (default_val, min_val, max_val) = extractDefaultMinMax(default_min_max_curly, param_name)
                    else:
                        error("ins: Expected default / min / max values for \"" & $param_name & "\" to be wrapped in curly brackets, or 'Buffer' to be declared.")

                    default_vals[statement_counter] = default_val
                    min_vals[statement_counter] = min_val
                    max_vals[statement_counter] = max_val
                
                #Just {0, 0, 1} / {0 0 1}, no param name provided!
                elif statement_kind == nnkCurly:
                    error("params: can't only use default / min / max without a name.")

                else:
                    error("params: Invalid syntax: '" & $(repr(statement)) & "'")

                statement_counter += 1
                    
        #Single "freq" {440, 0, 22000} OR "freq" on same line: params 1, "freq" {440, 0, 22000}
        elif params_names_kind == nnkCommand:
            error("params: syntax not implemented yet")

    #params count mismatch
    if not zero_params and statement_counter != params_number_VAL:
        error("params: Expected " & $params_number_VAL & " param names, got " & $statement_counter)

    #Remove trailing coma
    if params_names_string.len > 1:
        params_names_string = params_names_string[0..params_names_string.high-1]

    #Assign to node
    params_names_node = newLit(params_names_string)

    let
        defaults_mins_maxs = build_default_min_max_arrays(params_number_VAL, default_vals, min_vals, max_vals, params_names_string, true)
        params_generate_set_templates = params_generate_set_templates(min_vals, max_vals)
        params_generate_unpack_templates = params_generate_unpack_templates()

    if zero_params:
        params_number_VAL = 0
    
    return quote do:
        when not declared(declared_params):
            const 
                omni_params            {.inject.}  = `params_number_VAL`  
                omni_param_names_const {.inject.}  = `params_names_node`  #Used for IO.txt 
 
            let omni_param_names_let   {.inject.}  = `params_names_node`  #Used as global in C export

            #compile time variable if params are defined
            let declared_params {.inject, compileTime.} = true

            #const statement for defaults / mins / maxs
            `defaults_mins_maxs`

            #Returns a template that generates all setParams procs. This must be called after UGen definition
            `params_generate_set_templates`

            #Returns a template that generates the unpacking of params for perform block
            `params_generate_unpack_templates`

            #Export to C
            proc Omni_UGenParams() : int32 {.exportc: "Omni_UGenParams", dynlib.} =
                return int32(omni_params)

            proc Omni_UGenParamNames() : ptr cchar {.exportc: "Omni_UGenParamNames", dynlib.} =
                return cast[ptr cchar](unsafeAddr(omni_param_names_let[0]))

            proc Omni_UGenParamDefaults() : ptr cfloat {.exportc: "Omni_UGenParamDefaults", dynlib.} =
                return cast[ptr cfloat](omni_param_defaults_let.unsafeAddr)
        else:
            {.fatal: "params: Already defined once.".}

macro params*(args : varargs[untyped]) : untyped =
    var 
        params_number : int
        params_names  : NimNode
    
    let args_first = args[0]

    # params 1 
    # params: ... (dynamic counting)
    if args.len == 1:
        if args_first.kind == nnkIntLit:
            params_number = int(args_first.intVal)
        elif args_first.kind == nnkStmtList:
            params_names = args_first
            params_number = params_names.len
        else:
            error("params: invalid syntax: '" & repr(args) & "'. It must either be an integer literal or a statement list.")
    
    # params 1: ...
    elif args.len == 2:
        if args_first.kind == nnkIntLit:
            params_number = int(args_first.intVal)
            let args_second = args[1]
            if args_second.kind == nnkStmtList:
                params_names = args_second
            else:
                error("params: invalid statement list: '" & repr(args_second) & "'.")
        else:
            error("params: invalid first argument: '" & repr(args_first) & "'. First entry must be an integer literal.")

    else:
        error("params: invalid syntax: '" & repr(args) & "'. Too many arguments.")

    return quote do:
        params_inner(`params_number`, `params_names`)

#buffers

proc buffers_generate_set_templates() : NimNode {.compileTime.} =
    var
        setBuffer_if = nnkIfStmt.newTree()
        setBuffer_block = nnkStmtList.newTree(setBuffer_if)
        setBuffer = nnkProcDef.newTree(
            newIdentNode("Omni_UGenSetBuffer"),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("void"),
            nnkIdentDefs.newTree(
                newIdentNode("ugen"),
                nnkPtrTy.newTree(
                    newIdentNode("UGen")
                ),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("param"),
                newIdentNode("cstring"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("val"),
                newIdentNode("cstring"),
                newEmptyNode()
            )
            ),
            nnkPragma.newTree(
                newIdentNode("exportc"),
                newIdentNode("dynlib")
            ),
            newEmptyNode(),
            setBuffer_block
        )

    var 
        final_template_block = nnkStmtList.newTree()
        final_template = nnkTemplateDef.newTree(
            newIdentNode("generate_buffers_procs"),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("untyped")
            ),
            nnkPragma.newTree(
                newIdentNode("dirty")
            ),
            newEmptyNode(),
            final_template_block
        )

    result = nnkStmtList.newTree(
        final_template
    )

    if buffers_names_list.len > 0:
        for buffer_name in buffers_names_list:
            var
                omni_ugen_setbuffer_func_name = newIdentNode("Omni_UGenSetBuffer_" & buffer_name)

                set_buffer_func_block = nnkStmtList.newTree(
                    nnkCall.newTree(
                        nnkDotExpr.newTree(
                            nnkDotExpr.newTree(
                                newIdentNode("ugen"),
                                newIdentNode("buffers_lock")
                            ),
                            newIdentNode("spin")
                        ),
                        nnkStmtList.newTree(
                            nnkCall.newTree(
                                newIdentNode("omni_set_buffer_from_wrapper"),
                                nnkDotExpr.newTree(
                                    newIdentNode("ugen"),
                                    newIdentNode(buffer_name & "_buffer")
                                ),
                                newIdentNode("val")
                            )
                        )
                    )
                )

                set_buffer_func = nnkProcDef.newTree(
                    omni_ugen_setbuffer_func_name,
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("void"),
                        nnkIdentDefs.newTree(
                            newIdentNode("ugen"),
                            nnkPtrTy.newTree(
                                newIdentNode("UGen")
                            ),
                            newEmptyNode()
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("val"),
                            newIdentNode("cstring"),
                            newEmptyNode()
                        )
                    ),
                    nnkPragma.newTree(
                        newIdentNode("exportc"),
                        newIdentNode("dynlib")
                    ),
                    newEmptyNode(),
                    set_buffer_func_block
                )

            final_template_block.add(
                set_buffer_func
            )
            
            setBuffer_if.add(
                nnkElifBranch.newTree(
                    nnkInfix.newTree(
                        newIdentNode("=="),
                        newIdentNode("buffer"),
                        newLit(buffer_name)
                    ),
                    nnkStmtList.newTree(
                        nnkCall.newTree(
                            omni_ugen_setbuffer_func_name,
                            newIdentNode("ugen"),
                            newIdentNode("val")
                        )
                    )
                )
            )

        setBuffer_if.add(
            nnkElse.newTree(
                nnkStmtList.newTree(
                    nnkCall.newTree(
                        newIdentNode("omni_print"),
                        newLit("ERROR: Omni_UGenSetBuffer: invalid buffer name")
                    )
                )
            )
        )
    else:
        setBuffer_block[0] = nnkDiscardStmt.newTree(
            newEmptyNode()
        )

    final_template_block.add(
        setBuffer
    )

    #error repr result

proc buffers_generate_unpack_templates() : NimNode {.compileTime.} =
    var 
        init_block = nnkStmtList.newTree()
        unpack_buffers_init = nnkTemplateDef.newTree(
            newIdentNode("unpack_buffers_init"),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("untyped")
            ),
            nnkPragma.newTree(
                newIdentNode("dirty")
            ),
            newEmptyNode(),
            init_block
        )
        pre_init_block = nnkStmtList.newTree()
        unpack_buffers_pre_init = nnkTemplateDef.newTree(
            newIdentNode("unpack_buffers_pre_init"),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("untyped")
            ),
            nnkPragma.newTree(
                newIdentNode("dirty")
            ),
            newEmptyNode(),
            pre_init_block
        )
        perform_block = nnkStmtList.newTree()
        unpack_buffers_perform = nnkTemplateDef.newTree(
            newIdentNode("unpack_buffers_perform"),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("untyped")
            ),
            nnkPragma.newTree(
                newIdentNode("dirty")
            ),
            newEmptyNode(),
            perform_block
        )

    result = nnkStmtList.newTree(
        unpack_buffers_init,
        unpack_buffers_pre_init,
        unpack_buffers_perform
    )

    if buffers_names_list.len > 0:
        var 
            unpack_init = nnkStmtList.newTree()
            unpack_pre_init = nnkStmtList.newTree()
            unpack_perform = nnkStmtList.newTree()

        init_block.add(
            nnkCall.newTree(
                nnkDotExpr.newTree(
                nnkDotExpr.newTree(
                    newIdentNode("ugen"),
                    newIdentNode("buffers_lock")
                ),
                newIdentNode("spin")
                ),
                unpack_init
            )
        )

        pre_init_block.add(
            unpack_pre_init
        )

        perform_block.add(
            nnkCall.newTree(
                nnkDotExpr.newTree(
                nnkDotExpr.newTree(
                    newIdentNode("ugen"),
                    newIdentNode("buffers_lock")
                ),
                newIdentNode("spin")
                ),
                unpack_perform
            )
        )

        for i, buffer_name in buffers_names_list:
            let 
                buffer_name_ident = newIdentNode(buffer_name)
                buffer_name_buffer = newIdentNode(buffer_name & "_buffer")
            
            unpack_init.add(
               nnkAsgn.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("ugen"),
                        buffer_name_buffer
                    ),
                    nnkCall.newTree(
                        newIdentNode("omni_create_buffer_from_wrapper")
                    )
               )
            )

            unpack_pre_init.add(
                nnkVarSection.newTree(
                    nnkIdentDefs.newTree(
                        buffer_name_ident,
                        newIdentNode("Buffer"),
                        newEmptyNode()
                    )
                )
            )

            unpack_perform.add(
                nnkLetSection.newTree(
                    nnkIdentDefs.newTree(
                        buffer_name_ident,
                        newEmptyNode(),
                        nnkDotExpr.newTree(
                            newIdentNode("ugen"),
                            buffer_name_buffer
                        )
                    )
                )
            )
    else:
        init_block.add(
            nnkDiscardStmt.newTree(
                newEmptyNode()
            )
        )

        pre_init_block.add(
            nnkDiscardStmt.newTree(
                newEmptyNode()
            )
        )

        perform_block.add(
            nnkDiscardStmt.newTree(
                newEmptyNode()
            )
        )

    error repr result

proc buffer_generate_defaults(buffers_default : seq[string]) : NimNode {.compileTime.} =
    var
        defaults_array_bracket = nnkBracket.newTree()
        defaults_array_let = nnkLetSection.newTree(
            nnkIdentDefs.newTree(
                nnkPragmaExpr.newTree(
                    newIdentNode("omni_buffer_defaults_let"),
                    nnkPragma.newTree(
                        newIdentNode("inject")
                    )
                ),
                newEmptyNode(),
                defaults_array_bracket
            )
        ) 
        
        generate_defaults_block = nnkStmtList.newTree()
        generate_defaults = nnkTemplateDef.newTree(
            newIdentNode("generate_buffers_defaults"),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("untyped")
            ),
            nnkPragma.newTree(
                newIdentNode("dirty")
            ),
            newEmptyNode(),
            generate_defaults_block
        )

    result = nnkStmtList.newTree(
        defaults_array_let,
        generate_defaults
    )

    if buffers_names_list.len > 0:
        for i, buffer_name in buffers_names_list:
            let 
                buffer_default = buffers_default[i]
                buffer_default_lit = newLit(buffer_default)

            defaults_array_bracket.add(buffer_default_lit)

            if buffer_default != OMNI_DEFAULT_NIL_BUFFER:
                let omni_ugen_setbuffer_func_name = newIdentNode("Omni_UGenSetBuffer_" & buffer_name)
                
                generate_defaults_block.add(
                    nnkCall.newTree(
                        omni_ugen_setbuffer_func_name,
                        newIdentNode("ugen"),
                        
                    )
                )
    else:
        defaults_array_let[0][^1] = newLit("")
        generate_defaults[^1] = nnkStmtList.newTree(
            nnkDiscardStmt.newTree(
                newEmptyNode()
            )
        )

    #error repr result

macro buffers_inner*(buffers_number : typed, buffers_names : untyped) : untyped =
    var 
        buffers_number_VAL : int
        buffers_names_string : string = ""
        buffers_names_node : NimNode
        buffer_defaults : seq[string]

    let buffers_names_kind = buffers_names.kind

    #Must be an int literal OR nnkStmtListExpr (for buffers: 1)
    if buffers_number.kind == nnkIntLit: 
        buffers_number_VAL = int(buffers_number.intVal)     
    elif buffers_number.kind == nnkStmtListExpr:
        buffers_number_VAL = int(buffers_number[0].intVal)    
    else:
        error("buffers: Expected the number of buffers to be expressed as an integer literal value")

    if buffers_names_kind != nnkStmtList and buffers_names_kind != nnkStrLit and buffers_names_kind != nnkCommand and buffers_names_kind != nnkNilLit:
        error("buffers: Expected a block statement after the number of buffers")

    var zero_buffers = false

    if buffers_number_VAL > 0:
        at_least_one_buffer = true

    elif buffers_number_VAL == 0:
        buffers_number_VAL = 1
        zero_buffers = true
    
    elif buffers_number_VAL < 0:
        error("buffers: Expected a positive number for buffers number")

    var statement_counter = 0

    #This is for the buffers 1, buf case. (where buf is not viewed as varargs)
    if buffers_names_kind == nnkIdent:
        let buffer_name = buffers_names.strVal()
        checkValidParamName(buffer_name)
        buffers_names_string.add($buffer_name & ",")
        buffers_names_list.add(buffer_name)
        buffer_defaults.add(OMNI_DEFAULT_NIL_BUFFER)
        statement_counter = 1

    #block case
    else:
        #multiple statements: "freq" {440} OR "freq" {0, 22000} OR "freq" {0 22000} OR "freq" {440, 0, 22000} OR "freq" {440 0 22000}
        if buffers_names_kind == nnkStmtList:
            for statement in buffers_names.children():
                let statement_kind = statement.kind

                #buf
                if statement_kind == nnkIdent:
                    let buffer_name = statement.strVal()
                    checkValidParamName(buffer_name)
                    buffers_names_string.add($buffer_name & ",")
                    buffers_names_list.add(buffer_name)
                    buffer_defaults.add(OMNI_DEFAULT_NIL_BUFFER)
                
                #buf "buf1"
                elif statement_kind == nnkCommand:
                    assert statement.len == 2

                    let 
                        buffer_name_node = statement[0]
                        buffer_name_node_kind = buffer_name_node.kind
                        buffer_default = statement[1]
                        buffer_default_kind = buffer_default.kind
                    
                    if buffer_name_node_kind != nnkIdent:
                        error("buffers: Expected Buffer name number " & $(statement_counter + 1) & " to be either an identifier.")

                    let buffer_name = buffer_name_node.strVal()
                    checkValidParamName(buffer_name)
                    buffers_names_string.add($buffer_name & ",")
                    buffers_names_list.add(buffer_name)

                    if buffer_default_kind != nnkStrLit:
                        error("buffers: Buffer '" & $buffer_name & "' to have a string literal as default value.")

                    let buffer_default_name = buffer_default.strVal()
                    if buffer_default_name == OMNI_DEFAULT_NIL_BUFFER:
                        error("__OMNI_DEFAULT_NIL_BUFFER is reserved")
                    buffer_defaults.add(buffer_default_name)

                else:
                    error("buffers: Invalid syntax: '" & $(repr(statement)) & "'")

                statement_counter += 1
                    
        elif buffers_names_kind == nnkCommand:
            error("buffers: syntax not implemented yet")

    #buffers count mismatch
    if not zero_buffers and statement_counter != buffers_number_VAL:
        error("buffers: Expected " & $buffers_number_VAL & " buffer names, got " & $statement_counter)

    #Remove trailing coma
    if buffers_names_string.len > 1:
        buffers_names_string = buffers_names_string[0..buffers_names_string.high-1]

    #Assign to node
    buffers_names_node = newLit(buffers_names_string)

    let
        buffer_generate_defaults = buffer_generate_defaults(buffer_defaults)
        buffers_generate_set_templates = buffers_generate_set_templates()
        buffers_generate_unpack_templates = buffers_generate_unpack_templates()
    
    var when_declared_buffer_interface : NimNode

    if zero_buffers:
        buffers_number_VAL = 0
        when_declared_buffer_interface = nnkDiscardStmt.newTree(
            newEmptyNode()
        )
    else:
        when_declared_buffer_interface = nnkWhenStmt.newTree(
            nnkElifBranch.newTree(
                nnkPrefix.newTree(
                    newIdentNode("not"),
                    nnkCall.newTree(
                        newIdentNode("declared"),
                        newIdentNode("Buffer")
                    )
                ),
                nnkStmtList.newTree(
                    nnkPragma.newTree(
                        nnkExprColonExpr.newTree(
                            newIdentNode("fatal"),
                            newLit("buffers: no \'Buffer\' interface provided. This must come from an omni wrapper.")
                        )
                    )
                )
            )
        )
    
    return quote do:
        when not declared(declared_buffers):
            #Check buffer interface
            `when_declared_buffer_interface`
            
            #declare global vars
            const 
                omni_buffers            {.inject.}  = `buffers_number_VAL`  
                omni_buffer_names_const {.inject.}  = `buffers_names_node`  #Used for IO.txt 

            let omni_buffer_names_let   {.inject.}  = `buffers_names_node`  #Used as global exported to C

            #compile time variable if buffers are defined
            let declared_buffers {.inject, compileTime.} = true

            #Returns a const with default names and a template that calls the default init names (to be called in init)
            `buffer_generate_defaults`

            #Returns a template that generates all setbuffers procs. This must be called after UGen definition
            `buffers_generate_set_templates`

            #Returns a template that generates the unpacking of buffers for perform block
            `buffers_generate_unpack_templates`

            #Export to C
            proc Omni_UGenBuffers() : int32 {.exportc: "Omni_UGenBuffers", dynlib.} =
                return int32(omni_buffers)

            proc Omni_UGenBufferNames() : ptr cchar {.exportc: "Omni_UGenBufferNames", dynlib.} =
                return cast[ptr cchar](unsafeAddr(omni_buffer_names_let[0]))
            
            proc Omni_UGenBufferDefaults() : ptr cchar {.exportc: "Omni_UGenBufferDefaults", dynlib.} =
                return cast[ptr cchar](unsafeAddr(omni_buffer_defaults_let[0]))
        else:
            {.fatal: "buffers: Already defined once.".}

macro buffers*(args : varargs[untyped]) : untyped =
    var 
        buffers_number : int
        buffers_names  : NimNode
    
    let args_first = args[0]

    # buffers: ... (dynamic counting)
    if args.len == 1:
        if args_first.kind == nnkIntLit:
            buffers_number = int(args_first.intVal)
        elif args_first.kind == nnkStmtList:
            buffers_names = args_first
            buffers_number = buffers_names.len
        else:
            error("buffers: invalid syntax: '" & repr(args) & "'. It must either be an integer literal or a statement list.")
    
    # buffers 1: ...
    elif args.len == 2:
        if args_first.kind == nnkIntLit:
            buffers_number = int(args_first.intVal)
            let args_second = args[1]
            if args_second.kind == nnkStmtList:
                buffers_names = args_second
            else:
                error("buffers: invalid statement list: '" & repr(args_second) & "'.")
        else:
            error("buffers: invalid first argument: '" & repr(args_first) & "'. First entry must be an integer literal.")

    else:
        error("buffers: invalid syntax: '" & repr(args) & "'. Too many arguments.")

    return quote do:
        buffers_inner(`buffers_number`, `buffers_names`)