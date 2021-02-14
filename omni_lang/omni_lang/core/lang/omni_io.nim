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

import macros, strutils, omni_macros_utilities

const omni_max_inputs_outputs_const* = 128

#Some crazy number, used to detect if default is specified for either ins or params
const OMNI_RANDOM_FLOAT = -12312418241.1249124194

#Accepted chars for an in / param / buffer name
const omni_accepted_chars = {'a'..'z', 'A'..'Z', '0'..'9', '_'}

#default name when not specifying default buffer value
const
    OMNI_NIL = "NIL" 
    OMNI_DEFAULT_NIL_BUFFER = "NIL"

#Compile time arrays for params code generation. These are also used in omni_parser to add ins/params/buffers to declared_vars
var
    omni_ins_names_list*       {.compileTime.} : seq[string]
    omni_params_names_list*    {.compileTime.} : seq[string]
    omni_buffers_names_list*   {.compileTime.} : seq[string]

var omni_params_defaults_list* {.compileTime.} : seq[float]

var omni_at_least_one_buffer*  {.compileTime.} = false

proc omni_check_valid_name(param_name : string, which_call : string = "ins") : void =
    if param_name[0].isUpperAscii():
        error(which_call & ": input name '" & $param_name & "' must start with a lower case letter.")

    for individualChar in param_name:
        if not (individualChar in omni_accepted_chars):
            error(which_call & ": Invalid character '" & $individualChar & $ "' in input name '" & $param_name & "'")

###########
# outputs #
###########

proc omni_generate_min_max_procs(index : SomeInteger) : NimNode {.compileTime.} =
    let 
        in_num = "in" & $index
        in_min = in_num & "_omni_min"
        in_max = in_num & "_omni_max"
    
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
                        newIdentNode(in_num & "_omni_min_max")         
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

proc omni_generate_ar_in_template(index : SomeInteger) : NimNode {.compileTime.} =
    let 
        in_num : string = "in" & $(index)
        in_num_min : string = in_num & "_omni_min"
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
                                    newIdentNode("omni_ins_ptr"),
                                    newLit(index_minus_one)
                                ),
                                newIdentNode("omni_audio_index")
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
                                newIdentNode("omni_ins_ptr"),
                                newLit(index_minus_one)
                            ),
                            newIdentNode("omni_audio_index")
                        )
                    )
                )
            )
        )
    )

proc omni_generate_kr_in_template(index : SomeInteger) : NimNode {.compileTime.} =
    let 
        in_num : string = "in" & $(index)
        in_num_min : string = in_num & "_omni_min"
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
                                    newIdentNode("omni_ins_ptr"),
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
                                newIdentNode("omni_ins_ptr"),
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
macro omni_generate_inputs_templates*(num_of_inputs : typed, generate_ar : typed, generate_min_max : typed = 0) : untyped =
    var final_statement = nnkStmtList.newTree()

    var 
        num_of_inputs_VAL = num_of_inputs.intVal()
        generate_ar = generate_ar.intVal() #boolVal() doesn't work here.
        generate_min_max = generate_min_max.intVal()

    if generate_min_max == 1:
        for i in 1..num_of_inputs_VAL:
            final_statement.add(omni_generate_min_max_procs(i))

    if generate_ar == 1:
        for i in 1..num_of_inputs_VAL:
            final_statement.add(omni_generate_ar_in_template(i))

    else:
        for i in 1..num_of_inputs_VAL:
            final_statement.add(omni_generate_kr_in_template(i))
    
    return final_statement

proc omni_extract_default_min_max(default_min_max : NimNode, param_name : string) : tuple[defult : float, min : float, max : float] {.compileTime.} =
    let default_min_max_len = default_min_max.len()

    var 
        default_num : float = 0.0
        min_num     : float = OMNI_RANDOM_FLOAT
        max_num     : float = OMNI_RANDOM_FLOAT

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

        else:
            error("ins: Invalid syntax for input '" & $param_name & "'")

    return (default_num, min_num, max_num)

proc omni_build_default_min_max_arrays(num_of_inputs : int, default_vals : seq[float32], min_vals : seq[float], max_vals : seq[float], ins_names_string : string, ins_or_params : bool = false) : NimNode {.compileTime.} =
    let default_vals_len = default_vals.len()

    #Find mismatch. Perhaps user hasn't defined def/min/max for some params
    if num_of_inputs != default_vals_len:
        error("ins: Got " & $num_of_inputs & " number of inputs but only " & $default_vals_len & " default / min / max values.")

    result = nnkStmtList.newTree()

    var 
        in_or_param = "in"
        inputs_or_params = "inputs"

    if ins_or_params == true:
        in_or_param = "param"
        inputs_or_params = "params"

    var 
        default_min_max_const_section = nnkConstSection.newTree()
        defaults_array_const = nnkConstDef.newTree(
            nnkPragmaExpr.newTree(
                newIdentNode("omni_" & inputs_or_params & "_defaults_const"),
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
            omni_params_defaults_list.add(default_val)

        #Don't generate min max for param (will be calculated later)
        if not ins_or_params:
            if min_val != OMNI_RANDOM_FLOAT:
                default_min_max_const_section.add(
                    nnkConstDef.newTree(
                        nnkPragmaExpr.newTree(
                            newIdentNode(in_or_param & $(i_plus_one) & "_omni_min"),
                            nnkPragma.newTree(
                                newIdentNode("inject")
                            )
                        ),
                        newEmptyNode(),
                        newLit(min_val)
                    )
                )

            if max_val != OMNI_RANDOM_FLOAT:
                default_min_max_const_section.add(
                    nnkConstDef.newTree(
                        nnkPragmaExpr.newTree(
                            newIdentNode(in_or_param & $(i_plus_one) & "_omni_max"),
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

    #Declare min max as const, the array as both const (for static IO at the end of perform) and let (so i can get its memory address for Omni_UGenDefaults())
    result.add(default_min_max_const_section)

#This should be moved into its own "generate" function, as it is done for params and buffers...
#Right now, this is explicitly called in the parser for perform / sample functions 
macro omni_unpack_ins_perform*(ins_names : typed) : untyped =
    result = nnkStmtList.newTree()

    let ins_names_seq = ins_names.getImpl.strVal.split(',')
    
    for i, in_name in ins_names_seq:
        let in_number_name = ("in" & $(i+1))

        #let_statement will be overwritten if needed
        var
            ident_defs : NimNode
            let_statement = nnkDiscardStmt.newTree(
                newEmptyNode()
            )
        
        #Ignore OMNI_NIL (when ins == 0) AND in1, in2, etc...
        if in_name != OMNI_NIL and in_name != in_number_name:
            var ident_val = newIdentNode(in_number_name)

            ident_defs = nnkIdentDefs.newTree(
                newIdentNode(in_name),
                newEmptyNode(),
                ident_val
            )

            let_statement = nnkLetSection.newTree(ident_defs)

            result.add(let_statement)

macro omni_ins_inner*(ins_number : typed, ins_names : untyped = nil) : untyped =
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

    var zero_ins = false

    if ins_number_VAL == 0:
        ins_number_VAL = 1
        zero_ins = true
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
        min_vals[i] = OMNI_RANDOM_FLOAT
        max_vals[i] = OMNI_RANDOM_FLOAT

    var statement_counter = 0

    #This is for the inputs 1, "freq" case. (where "freq" is not viewed as varargs)
    #input 2, "freq", "stmt" is covered in the other macro
    if ins_names_kind == nnkStrLit or ins_names_kind == nnkIdent:
        if zero_ins:
            error("ins: Can't assign names when declaring 0 inputs.")
        let in_name = ins_names.strVal()
        omni_check_valid_name(in_name, "ins")
        ins_names_string.add(in_name & ",")
        omni_ins_names_list.add(in_name)
        statement_counter = 1

    #block case
    else:
        #multiple statements: "freq" {440} OR "freq" {0, 22000} OR "freq" {0 22000} OR "freq" {440, 0, 22000} OR "freq" {440 0 22000}
        if ins_names_kind == nnkStmtList:
            if zero_ins:
                error("ins: Can't assign names when declaring 0 inputs.")
            
            for statement in ins_names.children():
                let statement_kind = statement.kind

                #"freq" / freq
                if statement_kind == nnkStrLit or statement_kind == nnkIdent:
                    let in_name = statement.strVal()

                    omni_check_valid_name(in_name, "ins")
                    
                    ins_names_string.add(in_name & ",")
                    omni_ins_names_list.add(in_name)
                
                #"freq" {440, 0, 22000} OR "freq" {440 0 22000}
                elif statement_kind == nnkCommand:
                    assert statement.len == 2

                    #The name of the param
                    let 
                        in_name_node = statement[0]
                        in_name_node_kind = in_name_node.kind
                    if in_name_node_kind != nnkStrLit and in_name_node_kind != nnkIdent:
                        error("ins: Expected input name number " & $(statement_counter + 1) & " to be either an identifier or a string literal value")

                    let in_name = in_name_node.strVal()
                    omni_check_valid_name(in_name, "ins")

                    ins_names_string.add(in_name & ",")
                    omni_ins_names_list.add(in_name)
                
                    #The list of { }
                    let 
                        default_min_max = statement[1]
                        default_min_max_kind = default_min_max.kind

                    var 
                        default_val : float
                        min_val : float
                        max_val : float
   
                    if default_min_max_kind == nnkCurly:
                        (default_val, min_val, max_val) = omni_extract_default_min_max(default_min_max, in_name)

                    #single number literal: wrap in curly brackets
                    elif default_min_max_kind == nnkIntLit or default_min_max_kind == nnkFloatLit:
                        let default_min_max_curly = nnkCurly.newTree(default_min_max)
                        (default_val, min_val, max_val) = omni_extract_default_min_max(default_min_max_curly, in_name)
                    else:
                        error("ins: Expected default / min / max values for '" & $in_name & "' to be wrapped in curly brackets.")

                    default_vals[statement_counter] = default_val
                    min_vals[statement_counter] = min_val
                    max_vals[statement_counter] = max_val
                
                #Just {0, 0, 1} / {0 0 1}, no param name provided!
                elif statement_kind == nnkCurly:
                    let in_name = "in" & $(statement_counter+1)
                    
                    ins_names_string.add(in_name & ",")
                    omni_ins_names_list.add(in_name)

                    let (default_val, min_val, max_val) = omni_extract_default_min_max(statement, in_name)
                    
                    default_vals[statement_counter] = default_val
                    min_vals[statement_counter] = min_val
                    max_vals[statement_counter] = max_val

                else:
                    error("ins: Invalid syntax: '" & $(repr(statement)) & "'")

                statement_counter += 1
                    
        #Single "freq" {440, 0, 22000} OR "freq" on same line: ins 1, "freq" {440, 0, 22000}
        elif ins_names_kind == nnkCommand:
            error("ins: command syntax not implemented yet")

    #inputs count mismatch
    if not zero_ins:
        if ins_names_kind == nnkNilLit:
            for i in 0..ins_number_VAL-1:
                let in_name = "in" & $(i + 1)
                ins_names_string.add(in_name & ",")
                omni_ins_names_list.add(in_name)
        else:
            if statement_counter != ins_number_VAL:
                error("ins: Expected " & $ins_number_VAL & " input names, got " & $statement_counter)

        #Remove trailing coma
        if ins_names_string.len > 1:
            ins_names_string.removeSuffix(',')

    #Assign to node
    ins_names_node = newLit(ins_names_string)

    let defaults_mins_maxs = omni_build_default_min_max_arrays(ins_number_VAL, default_vals, min_vals, max_vals, ins_names_string)

    if zero_ins:
        ins_names_node = newLit(OMNI_NIL)
        ins_number_VAL = 0

    return quote do:
        when not declared(omni_declared_inputs):
            const 
                omni_inputs             {.inject.} = `ins_number_VAL`  
                ins                     {.inject.} = omni_inputs      #Better alias to use in omni code  
                omni_inputs_names_const {.inject.} = `ins_names_node` #Used in omni_io.txt

            #compile time variable if ins are defined
            let omni_declared_inputs {.inject, compileTime.} = true

            #const statement for defaults / mins / maxs
            `defaults_mins_maxs`
            
            #Generate all access templates (kr) and procs for min / max
            #The kr will only work in perform, not init, as omni_ins_ptr is not defined
            #However, this is quite an ugly error, clean this stuff up
            omni_generate_inputs_templates(`ins_number_VAL`, 0, 1)

            #For ins[i] access
            proc omni_get_dynamic_input[T : Float32_ptr_ptr or Float64_ptr_ptr; Y : SomeNumber](omni_ins_ptr : T, chan : Y, omni_audio_index : int = 0) : float =
                let chan_int = int(chan)
                if chan_int < omni_inputs:
                    return omni_ins_ptr[chan_int][omni_audio_index]
                else:
                    return 0.0
            
            #Export to C
            proc Omni_UGenInputs() : int32 {.exportc: "Omni_UGenInputs", dynlib.} =
                return int32(omni_inputs)

            proc Omni_UGenInputsNames() : ptr cchar {.exportc: "Omni_UGenInputNames", dynlib.} =
                return cast[ptr cchar](omni_inputs_names_const)

            proc Omni_UGenInputsDefaults() : ptr cfloat {.exportc: "Omni_UGenInputDefaults", dynlib.} =
                return cast[ptr cfloat](omni_inputs_defaults_const.unsafeAddr)
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
        omni_ins_inner(`ins_number`, `ins_names`)

#inputs == ins
macro inputs*(args : varargs[untyped]) : untyped =
    return quote do:
        ins(`args`)

###########
# outputs #
###########

#This is called directly in the parser for perform / sample
macro omni_generate_outputs_templates*(num_of_outputs : typed) : untyped =
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
                    newIdentNode("omni_outs_ptr"),             #name of the outs buffer
                    newLit(int(i - 1))               #literal value
                ),
                newIdentNode("omni_audio_index") #name of the looping variable
            )
            )
        )

        #Accumulate result
        final_statement.add(temp_in_stmt_list)

    return final_statement

macro omni_outs_inner*(outs_number : typed, outs_names : untyped = nil) : untyped =
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
            if not (individualChar in omni_accepted_chars):
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

            omni_check_valid_name(param_name, "outs")
            
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
        outs_names_string.removeSuffix(',')

    #Assign to node
    outs_names_node = newLit(outs_names_string)

    return quote do: 
        when not declared(omni_declared_outputs):
            const 
                omni_outputs             {.inject.} = `outs_number_VAL`
                outs                     {.inject.} = omni_outputs      #Better alias to use in omni code
                omni_outputs_names_const {.inject.} = `outs_names_node` #Used in omni_io.txt
            
            #compile time variable if outs are defined
            let omni_declared_outputs {.inject, compileTime.} = true
            
            #Export to C
            proc Omni_UGenOutputs() : int32 {.exportc: "Omni_UGenOutputs", dynlib.} =
                return int32(omni_outputs)

            proc Omni_UGenOutputsNames() : ptr cchar {.exportc: "Omni_UGenOutputNames", dynlib.} =
                return cast[ptr cchar](omni_outputs_names_const)
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
        omni_outs_inner(`outs_number`, `outs_names`)

#outputs == outs
macro outputs*(args : varargs[untyped]) : untyped =
    return quote do:
        outs(`args`)

##########
# params #
##########

#Returns a template that generates all set procs, including setParam
proc omni_params_generate_set_templates(min_vals : seq[float], max_vals : seq[float]) : NimNode {.compileTime.} =
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
                newIdentNode("omni_ugen_ptr"),
                newIdentNode("pointer"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("param"),
                newIdentNode("cstring"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("value"),
                newIdentNode("cdouble"),
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
            newIdentNode("omni_generate_params_set_procs"),
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

    if omni_params_names_list.len > 0:
        var error_str = "ERROR: Omni_UGenSetParam: invalid param name. Valid param names are:"
        
        for i, param_name in omni_params_names_list:
            let 
                param_name_param = newIdentNode(param_name & "_omni_param")
                param_dot_expr = nnkDotExpr.newTree(
                    newIdentNode("omni_ugen"),
                    param_name_param
                )

            #Individual lock per param
            when defined(omni_locks_multi_param_lock):
                var param_lock = nnkDotExpr.newTree(
                    param_dot_expr,
                    newIdentNode("lock")
                )
            
            #Global (UGen) param lock
            else:
                var param_lock = nnkDotExpr.newTree(
                    newIdentNode("omni_ugen"),
                    newIdentNode("omni_params_lock")
                )

            var 
                omni_ugen_setparam_func_name = newIdentNode("Omni_UGenSetParam_" & param_name)

                omni_ugen = nnkLetSection.newTree(
                    nnkIdentDefs.newTree(
                        newIdentNode("omni_ugen"),
                        newEmptyNode(),
                        nnkCast.newTree(
                            newIdentNode("Omni_UGen"),
                            newIdentNode("omni_ugen_ptr")
                        )
                    )
                )

                set_param_spin = nnkCall.newTree(
                    nnkDotExpr.newTree(
                        param_lock,
                        newIdentNode("spinParamLock")
                    )
                )

                set_param_func_block = nnkStmtList.newTree(
                    nnkIfStmt.newTree(
                        nnkElifBranch.newTree(
                            nnkCall.newTree(
                                newIdentNode("not"),
                                nnkCall.newTree(
                                    newIdentNode("isNil"),
                                    newIdentNode("omni_ugen_ptr")
                                )
                            ),
                            nnkStmtList.newTree(
                                omni_ugen,
                                set_param_spin
                            )
                        )
                    )
                )

                set_param_func = nnkProcDef.newTree(
                    omni_ugen_setparam_func_name,
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("void"),
                        nnkIdentDefs.newTree(
                            newIdentNode("omni_ugen_ptr"),
                            newIdentNode("pointer"),
                            newEmptyNode()
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("value"),
                            newIdentNode("cdouble"),
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
                set_min_max_template_name = newIdentNode("omni_param_" & param_name & "_min_max")
                set_min_max_template_block_if = nnkIfStmt.newTree()
                set_min_max_template = nnkTemplateDef.newTree(
                    set_min_max_template_name,
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("untyped"),
                        nnkIdentDefs.newTree(
                            newIdentNode("in_val"),
                            newIdentNode("untyped"),
                            newEmptyNode()
                        )
                    ),
                    nnkPragma.newTree(
                        newIdentNode("dirty")
                    ),
                    newEmptyNode(),
                    nnkStmtList.newTree(
                        set_min_max_template_block_if
                    )
                )
                
                set_min_val = false
                set_max_val = false

            #if valid min_val, use it
            if min_val != OMNI_RANDOM_FLOAT:
                let min_val_lit = newFloatLitNode(min_val)
                   
                set_min_max_template_block_if.add(
                    nnkElifBranch.newTree(
                        nnkInfix.newTree(
                            newIdentNode("<"),
                            newIdentNode("in_val"),
                            min_val_lit
                        ),
                        nnkStmtList.newTree(
                            min_val_lit
                        )
                    )
                )

                set_min_val = true

            #if valid max val, use it
            if max_val != OMNI_RANDOM_FLOAT:
                let max_val_lit = newFloatLitNode(max_val)

                set_min_max_template_block_if.add(
                    nnkElifBranch.newTree(
                        nnkInfix.newTree(
                            newIdentNode(">"),
                            newIdentNode("in_val"),
                            max_val_lit
                        ),
                        nnkStmtList.newTree(
                            max_val_lit
                        )
                    )
                )
                
                set_max_val = true

            let val_assgn = nnkAsgn.newTree(
                nnkDotExpr.newTree(
                    param_dot_expr,
                    newIdentNode("value")
                ),
                nnkCall.newTree(
                    set_min_max_template_name,
                    newIdentNode("value")
                )
            )

            let initialized_param = nnkIfStmt.newTree(
                nnkElifBranch.newTree(
                    nnkCall.newTree(
                        newIdentNode("not"),
                        nnkDotExpr.newTree(
                            param_dot_expr,
                            newIdentNode("init")
                        )
                    ),
                    nnkStmtList.newTree(
                        nnkAsgn.newTree(
                            nnkDotExpr.newTree(
                                param_dot_expr,
                                newIdentNode("init")
                            ),
                            newLit(true)
                        ),
                        nnkAsgn.newTree(
                            nnkDotExpr.newTree(
                                param_dot_expr,
                                newIdentNode("prev_value")
                            ),
                            nnkDotExpr.newTree(
                                param_dot_expr,
                                newIdentNode("value")
                            )
                        ),
                    )
                )
            )

            set_param_spin.add(
                nnkStmtList.newTree(
                    val_assgn,
                    initialized_param
                )
            )  
        
            if set_min_val or set_max_val:
                set_min_max_template_block_if.add(
                    nnkElse.newTree(
                        newIdentNode("in_val")
                    )
                )
            else:
                set_min_max_template[^1] = nnkStmtList.newTree(
                    newIdentNode("in_val")
                )

            final_template_block.add(
                set_min_max_template,
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
                            newIdentNode("omni_ugen_ptr"),
                            newIdentNode("value")
                        )
                    )
                )
            )

            error_str.add(" '" & param_name & "',")
        
        error_str.removeSuffix(',')

        setParam_if.add(
            nnkElse.newTree(
                nnkStmtList.newTree(
                    nnkCall.newTree(
                        newIdentNode("omni_print_str"),
                        newLit(error_str)
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
proc omni_params_generate_unpack_templates() : NimNode {.compileTime.} =
    var 
        pre_init_block = nnkStmtList.newTree()
        omni_unpack_params_pre_init = nnkTemplateDef.newTree(
            newIdentNode("omni_unpack_params_pre_init"),
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
        init_block = nnkStmtList.newTree()
        omni_unpack_params_init = nnkTemplateDef.newTree(
            newIdentNode("omni_unpack_params_init"),
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
        perform_block = nnkStmtList.newTree()
        omni_unpack_params_perform = nnkTemplateDef.newTree(
            newIdentNode("omni_unpack_params_perform"),
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
        omni_unpack_params_pre_init,
        omni_unpack_params_init,
        omni_unpack_params_perform
    )

    if omni_params_names_list.len > 0:
        var unpack_pre_init = nnkStmtList.newTree()
        
        pre_init_block.add(
            unpack_pre_init
        )
        
        #Using global (UGen's) param lock
        when not defined(omni_locks_multi_param_lock):
            var
                unpack_init = nnkStmtList.newTree()
                unpack_perform_declare_params = nnkStmtList.newTree()
                unpack_perform_success = nnkStmtList.newTree()
                unpack_perform_fail = nnkStmtList.newTree()
                unpack_perform_let  = nnkStmtList.newTree()

            init_block.add(
                nnkCall.newTree(
                    nnkDotExpr.newTree(
                        nnkDotExpr.newTree(
                            newIdentNode("omni_ugen"),
                            newIdentNode("omni_params_lock")
                        ),
                        newIdentNode("spinParamLock")
                    ),
                    unpack_init 
                )
            )

            perform_block.add(
                unpack_perform_declare_params,
                nnkIfStmt.newTree(
                    nnkElifBranch.newTree(
                        nnkCall.newTree(
                            newIdentNode("acquireParamLock"),
                            nnkDotExpr.newTree(
                                newIdentNode("omni_ugen"),
                                newIdentNode("omni_params_lock")
                            )
                        ),
                        nnkStmtList.newTree(
                            unpack_perform_success,
                            nnkCall.newTree(
                                newIdentNode("releaseParamLock"),
                                nnkDotExpr.newTree(
                                    newIdentNode("omni_ugen"),
                                    newIdentNode("omni_params_lock")
                                )
                            )
                        )
                    ),
                    nnkElse.newTree(
                        unpack_perform_fail
                    )
                ),
                unpack_perform_let
            )

        for i, param_name in omni_params_names_list:        
            let 
                param_name_ident  = newIdentNode(param_name)
                param_name_unique = genSymUntyped(param_name)
                param_name_param  = newIdentNode(param_name & "_omni_param")
                omni_ugen_param_dot_expr = nnkDotExpr.newTree(
                    newIdentNode("omni_ugen"),
                    param_name_param
                )

            unpack_pre_init.add(
                nnkLetSection.newTree(
                    nnkIdentDefs.newTree(
                        param_name_ident,
                        newEmptyNode(),
                        newFloatLitNode(0)
                    )
                )
            )

            #Using individual param's lock
            when defined(omni_locks_multi_param_lock):
                var param_lock = nnkDotExpr.newTree(
                    newIdentNode("omni_ugen"),
                    nnkDotExpr.newTree(
                        param_name_ident,
                        newIdentNode("lock")
                    )
                )
                var
                    unpack_init = nnkStmtList.newTree()
                    unpack_perform_declare_params = nnkStmtList.newTree()
                    unpack_perform_success = nnkStmtList.newTree()
                    unpack_perform_fail = nnkStmtList.newTree()
                    unpack_perform_let  = nnkStmtList.newTree()
                
                init_block.add(
                    nnkCall.newTree(
                        nnkDotExpr.newTree(
                            param_lock,
                            newIdentNode("spinParamLock")
                        ),
                        unpack_init 
                    )
                )

                perform_block.add(
                    unpack_perform_declare_params,
                    nnkIfStmt.newTree(
                        nnkElifBranch.newTree(
                            nnkCall.newTree(
                                newIdentNode("acquireParamLock"),
                                param_lock
                            ),
                            nnkStmtList.newTree(
                                unpack_perform_success,
                                nnkCall.newTree(
                                    newIdentNode("releaseParamLock"),
                                    param_lock
                                )
                            )
                        ),
                        nnkElse.newTree(
                            unpack_perform_fail
                        )
                    ),
                    unpack_perform_let
                )
                
            unpack_init.add(
                nnkIfStmt.newTree(
                    nnkElifBranch.newTree(
                        nnkCall.newTree(
                            newIdentNode("not"),
                            nnkDotExpr.newTree(
                                omni_ugen_param_dot_expr,
                                newIdentNode("init")
                            )
                        ),
                        nnkStmtList.newTree(
                            nnkAsgn.newTree(
                                nnkDotExpr.newTree(
                                    omni_ugen_param_dot_expr,
                                    newIdentNode("value")
                                ),
                                newFloatLitNode(
                                    omni_params_defaults_list[i]
                                )
                            ),

                            nnkAsgn.newTree(
                                nnkDotExpr.newTree(
                                    omni_ugen_param_dot_expr,
                                    newIdentNode("prev_value")
                                ),
                                newFloatLitNode(
                                    omni_params_defaults_list[i]
                                )
                            ),

                            nnkAsgn.newTree(
                                nnkDotExpr.newTree(
                                    omni_ugen_param_dot_expr,
                                    newIdentNode("init")
                                ),
                                newLit(true)           
                            )
                        )
                    )
                ),

                nnkLetSection.newTree(
                    nnkIdentDefs.newTree(
                        param_name_ident,
                        newEmptyNode(),
                        nnkDotExpr.newTree(
                            nnkDotExpr.newTree(
                                newIdentNode("omni_ugen"),
                                param_name_param
                            ),
                            newIdentNode("value")
                        )
                    )
                )
            )

            unpack_perform_declare_params.add(
                #Cheap solution, using var
                nnkVarSection.newTree(
                    nnkIdentDefs.newTree(
                        param_name_unique,
                        getType(float),
                        newEmptyNode()
                    )
                )
            )

            unpack_perform_success.add(
                nnkAsgn.newTree(
                    param_name_unique,
                    nnkDotExpr.newTree(
                        nnkDotExpr.newTree(
                            newIdentNode("omni_ugen"),
                            param_name_param
                        ),
                        newIdentNode("value")
                    )
                ),
                nnkAsgn.newTree(
                    nnkDotExpr.newTree(
                        nnkDotExpr.newTree(
                            newIdentNode("omni_ugen"),
                            param_name_param
                        ),
                        newIdentNode("prev_value")
                    ),
                    param_name_unique
                )
            )

            unpack_perform_fail.add(
                nnkAsgn.newTree(
                    param_name_unique,
                    nnkDotExpr.newTree(
                        nnkDotExpr.newTree(
                            newIdentNode("omni_ugen"),
                            param_name_param
                        ),
                        newIdentNode("prev_value")
                    )
                )
            )

            unpack_perform_let.add(
                nnkLetSection.newTree(
                    nnkIdentDefs.newTree(
                        param_name_ident,
                        newEmptyNode(),
                        param_name_unique
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
    
    #error repr result

#For params[0] syntax. Returns prev_value as it's equal to current value if thread has lock!
proc omni_generate_get_dynamic_param_template() : NimNode {.compileTime.} =
    if omni_params_names_list.len > 0:
        var if_stmt = nnkIfStmt.newTree()
        
        result = newProc(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("omni_get_dynamic_param")
            ),
            [ 
                newIdentNode("untyped"),
                nnkIdentDefs.newTree(
                    newIdentNode("index"),
                    newIdentNode("SomeNumber"),
                    newLit(0)
                )
            ],
            pragmas = nnkPragma.newTree(
                newIdentNode("dirty")
            ),
            body = nnkStmtList.newTree(
                nnkPar.newTree(
                    if_stmt
                )
            ),
            procType = nnkTemplateDef
        )

        for index, param_name in omni_params_names_list:
            if_stmt.add(
                nnkElifBranch.newTree(
                    nnkInfix.newTree(
                        newIdentNode("=="),
                        nnkCall.newTree(
                            newIdentNode("int"),
                            newIdentNode("index")
                        ),
                        newLit(index)
                    ),
                    newIdentNode(param_name)
                )
            )
        
        if_stmt.add(
            nnkElse.newTree(
                newFloatLitNode(0.0)
            )
        )
    else:
        return nnkDiscardStmt.newTree(
            newEmptyNode()
        )
    
    #error repr result

macro omni_params_inner*(params_number : typed, params_names : untyped) : untyped =
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
        min_vals[i] = OMNI_RANDOM_FLOAT
        max_vals[i] = OMNI_RANDOM_FLOAT

    var statement_counter = 0

    #This is for the params 1, "freq" case. (where "freq" is not viewed as varargs)
    #param 2, "freq", "stmt" is covered in the other macro
    if params_names_kind == nnkStrLit or params_names_kind == nnkIdent:
        if zero_params:
            error("params: Can't assign names when declaring 0 params.")
        let param_name = params_names.strVal()
        omni_check_valid_name(param_name, "params")
        params_names_string.add($param_name & ",")
        statement_counter = 1

    #block case
    else:
        #multiple statements: "freq" {440} OR "freq" {0, 22000} OR "freq" {0 22000} OR "freq" {440, 0, 22000} OR "freq" {440 0 22000}
        if params_names_kind == nnkStmtList:
            if zero_params:
                error("params: Can't assign names when declaring 0 params.")
            
            for statement in params_names.children():
                let statement_kind = statement.kind

                #"freq" / freq
                if statement_kind == nnkStrLit or statement_kind == nnkIdent:
                    let param_name = statement.strVal()

                    omni_check_valid_name(param_name, "params")
                    
                    params_names_string.add($param_name & ",")
                    omni_params_names_list.add(param_name)
                
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
                    omni_check_valid_name(param_name, "params")

                    params_names_string.add($param_name & ",")
                    omni_params_names_list.add(param_name)
                
                    #The list of { }
                    let 
                        default_min_max = statement[1]
                        default_min_max_kind = default_min_max.kind

                    var 
                        default_val : float
                        min_val : float
                        max_val : float
   
                    if default_min_max_kind == nnkCurly:
                        (default_val, min_val, max_val) = omni_extract_default_min_max(default_min_max, param_name)

                    #single number literal: wrap in curly brackets
                    elif default_min_max_kind == nnkIntLit or default_min_max_kind == nnkFloatLit:
                        let default_min_max_curly = nnkCurly.newTree(default_min_max)
                        (default_val, min_val, max_val) = omni_extract_default_min_max(default_min_max_curly, param_name)
                    else:
                        error("ins: Expected default / min / max values for '" & $param_name & "' to be wrapped in curly brackets.")

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
            error("params: command syntax not implemented yet")

    #params count mismatch
    if not zero_params:
        if params_names_kind == nnkNilLit:
            for i in 0..params_number_VAL-1:
                let param_name = "param" & $(i + 1)
                params_names_string.add(param_name & ",")
                omni_params_names_list.add(param_name)
        else:
            if statement_counter != params_number_VAL:
                error("params: Expected " & $params_number_VAL & " param names, got " & $statement_counter)

        #Remove trailing coma
        if params_names_string.len > 1:
            params_names_string.removeSuffix(',')

    #Assign to node
    params_names_node = newLit(params_names_string)

    let
        defaults_mins_maxs = omni_build_default_min_max_arrays(params_number_VAL, default_vals, min_vals, max_vals, params_names_string, true)
        omni_params_generate_set_templates = omni_params_generate_set_templates(min_vals, max_vals)
        omni_generate_get_dynamic_param_template = omni_generate_get_dynamic_param_template()
        omni_params_generate_unpack_templates = omni_params_generate_unpack_templates()

    if zero_params:
        params_names_node = newLit(OMNI_NIL)
        params_number_VAL = 0
    
    return quote do:
        when not declared(omni_declared_params):
            const 
                omni_params             {.inject.}  = `params_number_VAL`  
                params                  {.inject.}  = omni_params         #Better alias to use in omni code
                omni_params_names_const {.inject.}  = `params_names_node` #Used for omni_io.txt 

            #compile time variable if params are defined
            let omni_declared_params {.inject, compileTime.} = true

            #const statement for defaults / mins / maxs
            `defaults_mins_maxs`

            #Returns a template that generates all setParams procs. This must be called after Omni_UGen definition
            `omni_params_generate_set_templates`

            #Returns a template that generates the unpacking of params for perform block
            `omni_params_generate_unpack_templates`

            #Returns a template for dynamic params access, params[i]
            `omni_generate_get_dynamic_param_template`

            #Export to C
            proc Omni_UGenParams() : int32 {.exportc: "Omni_UGenParams", dynlib.} =
                return int32(omni_params)

            proc Omni_UGenParamsNames() : ptr cchar {.exportc: "Omni_UGenParamNames", dynlib.} =
                return cast[ptr cchar](omni_params_names_const)

            proc Omni_UGenParamsDefaults() : ptr cfloat {.exportc: "Omni_UGenParamDefaults", dynlib.} =
                return cast[ptr cfloat](omni_params_defaults_const.unsafeAddr)
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
        omni_params_inner(`params_number`, `params_names`)

#parameters == params
macro parameters*(args : varargs[untyped]) : untyped =
    return quote do:
        params(`args`)

###########
# buffers #
###########

proc omni_buffers_generate_set_templates() : NimNode {.compileTime.} =
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
                newIdentNode("omni_ugen_ptr"),
                newIdentNode("pointer"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("buffer"),
                newIdentNode("cstring"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("value"),
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
            newIdentNode("omni_generate_buffers_set_procs"),
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

    if omni_buffers_names_list.len > 0:
        var error_str = "ERROR: Omni_UGenSetBuffer: invalid buffer name. Valid buffer names are:"
        for buffer_name in omni_buffers_names_list:
            var
                buffer_dot_expr = nnkDotExpr.newTree(
                    newIdentNode("omni_ugen"),
                    newIdentNode(buffer_name & "_omni_buffer")
                )
                omni_ugen_setbuffer_func_name = newIdentNode("Omni_UGenSetBuffer_" & buffer_name)

                omni_ugen = nnkLetSection.newTree(
                    nnkIdentDefs.newTree(
                        newIdentNode("omni_ugen"),
                        newEmptyNode(),
                        nnkCast.newTree(
                            newIdentNode("Omni_UGen"),
                            newIdentNode("omni_ugen_ptr")
                        )
                    )
                )

                set_buffer_spin = nnkCall.newTree(
                    nnkDotExpr.newTree(
                        nnkDotExpr.newTree(
                            newIdentNode("omni_ugen"),
                            newIdentNode("omni_buffers_lock")
                        ),
                        newIdentNode("spinBufferLock")
                    ),
                    nnkStmtList.newTree(
                        nnkIfStmt.newTree(
                            nnkElifBranch.newTree(
                                nnkCall.newTree(
                                    newIdentNode("not"),
                                    nnkCall.newTree(
                                        newIdentNode("isNil"),
                                        nnkCast.newTree(
                                            newIdentNode("pointer"),
                                            buffer_dot_expr
                                        )
                                    )
                                ),
                                nnkStmtList.newTree(
                                    nnkCall.newTree(
                                        newIdentNode("omni_update_buffer"),
                                        buffer_dot_expr,
                                        newIdentNode("value")
                                    )
                                )
                            ),
                            nnkElse.newTree(
                                nnkStmtList.newTree(
                                    nnkCall.newTree(
                                        newIdentNode("omni_print_str"),
                                        newLit("ERROR: Omni_UGenSetBuffer: Can't set '" & buffer_name & "' before running Omni_UGenInit.")
                                    )
                                )
                            )
                        )
                    )
                )

                set_buffer_func_block = nnkStmtList.newTree(
                     nnkIfStmt.newTree(
                        nnkElifBranch.newTree(
                            nnkCall.newTree(
                                newIdentNode("not"),
                                nnkCall.newTree(
                                    newIdentNode("isNil"),
                                    newIdentNode("omni_ugen_ptr")
                                )
                            ),
                            nnkStmtList.newTree(
                                omni_ugen,
                                set_buffer_spin
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
                            newIdentNode("omni_ugen_ptr"),
                            newIdentNode("pointer"),
                            newEmptyNode()
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("value"),
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
                            newIdentNode("omni_ugen_ptr"),
                            newIdentNode("value")
                        )
                    )
                )
            )

            error_str.add(" '" & buffer_name & "',")

        error_str.removeSuffix(',')
        
        setBuffer_if.add(
            nnkElse.newTree(
                nnkStmtList.newTree(
                    nnkCall.newTree(
                        newIdentNode("omni_print_str"),
                        newLit(error_str)
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

proc omni_buffers_generate_unpack_templates() : NimNode {.compileTime.} =
    var 
        init_block = nnkStmtList.newTree()
        unpack_buffers_init = nnkTemplateDef.newTree(
            newIdentNode("omni_unpack_buffers_init"),
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
            newIdentNode("omni_unpack_buffers_pre_init"),
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
        omni_unpack_buffers_perform = nnkTemplateDef.newTree(
            newIdentNode("omni_unpack_buffers_perform"),
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
        omni_unpack_buffers_perform
    )

    if omni_buffers_names_list.len > 0:
        var 
            unpack_init = nnkStmtList.newTree()
            unpack_pre_init = nnkStmtList.newTree()
            unpack_perform = nnkStmtList.newTree()

        init_block.add(
            unpack_init
        )

        pre_init_block.add(
            unpack_pre_init
        )

        perform_block.add(
            unpack_perform
        )

        for i, buffer_name in omni_buffers_names_list:
            let 
                buffer_name_ident = newIdentNode(buffer_name)
                buffer_name_buffer = newIdentNode(buffer_name & "_omni_buffer")
            
            unpack_init.add(
               nnkAsgn.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("omni_ugen"),
                        buffer_name_buffer
                    ),
                    nnkCall.newTree(
                        newIdentNode("omni_init_buffer"),
                        newLit(buffer_name)
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
                            newIdentNode("omni_ugen"),
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

    #error repr result

proc omni_buffers_generate_defaults(buffers_default : seq[string]) : NimNode {.compileTime.} =
    var
        defaults_array_bracket = nnkBracket.newTree()
        defaults_array_const_unpacked_str : string
        
        defaults_array_const = nnkConstSection.newTree(
            nnkConstDef.newTree(
                nnkPragmaExpr.newTree(
                    newIdentNode("omni_buffers_defaults_const"),
                    nnkPragma.newTree(
                        newIdentNode("inject")
                    )
                ),
                newEmptyNode(),
                defaults_array_bracket
            ), 

            nnkConstDef.newTree(
                nnkPragmaExpr.newTree(
                    newIdentNode("omni_buffers_defaults_const_unpacked"),
                    nnkPragma.newTree(
                        newIdentNode("inject")
                    )
                ),
                newEmptyNode(),
                newLit("") #this gets subbed at end of function
            )
        )
        
        generate_defaults_block = nnkStmtList.newTree()
        generate_defaults = nnkTemplateDef.newTree(
            newIdentNode("omni_set_buffers_defaults"),
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
        defaults_array_const,
        generate_defaults
    )

    if omni_buffers_names_list.len > 0:
        for i, buffer_name in omni_buffers_names_list:
            let 
                buffer_default = buffers_default[i]
                buffer_default_lit = newLit(buffer_default)

            defaults_array_bracket.add(buffer_default_lit)
            defaults_array_const_unpacked_str.add(buffer_default & ",")

            if buffer_default != OMNI_DEFAULT_NIL_BUFFER:
                let omni_ugen_setbuffer_func_name = newIdentNode("Omni_UGenSetBuffer_" & buffer_name)
                
                generate_defaults_block.add(
                    nnkCall.newTree(
                        omni_ugen_setbuffer_func_name,
                        newIdentNode("omni_ugen"),
                        buffer_default_lit
                    )     
                )

        # remove trailing ,
        defaults_array_const_unpacked_str.removeSuffix(',')
    else:
        defaults_array_const_unpacked_str = OMNI_NIL
        let nil_array = nnkBracket.newTree(
            newLit(OMNI_NIL)
        )
        defaults_array_const[0][^1] = nil_array

    if generate_defaults[^1].len == 0:
        generate_defaults[^1].add(
            nnkDiscardStmt.newTree(
                newEmptyNode()
            )
        )

    # replace the defaults_array_const_unpacked_str to the decl
    defaults_array_const[1][^1] = newLit(defaults_array_const_unpacked_str)

    #error repr result

proc omni_generate_lock_unlock_buffers() : NimNode {.compileTime.} =
    result = nnkStmtList.newTree()

    var 
        unlock_buffers_body = nnkStmtList.newTree()
        unlock_buffers_template = nnkTemplateDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("omni_unlock_buffers")
            ),
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
                nnkWhenStmt.newTree(
                    nnkElifBranch.newTree(
                        nnkInfix.newTree(
                            newIdentNode("and"),
                            newIdentNode("omni_at_least_one_buffer"),
                            nnkCall.newTree(
                                newIdentNode("not"),
                                nnkCall.newTree(
                                    newIdentNode("defined"),
                                    newIdentNode("omni_buffers_disable_multithreading")
                                )
                            )
                        ),
                        unlock_buffers_body
                    )
                )
            )
        )

        silence = nnkStmtList.newTree(
            nnkForStmt.newTree(
                newIdentNode("omni_audio_channel"),
                nnkInfix.newTree(
                    newIdentNode("..<"),
                    newLit(0),
                    newIdentNode("omni_outputs")
                ),
                nnkStmtList.newTree(
                    nnkForStmt.newTree(
                        newIdentNode("omni_audio_index"),
                        nnkInfix.newTree(
                            newIdentNode("..<"),
                            newLit(0),
                            newIdentNode("bufsize")
                        ),
                        nnkStmtList.newTree(
                            nnkAsgn.newTree(
                                nnkBracketExpr.newTree(
                                    nnkBracketExpr.newTree(
                                        newIdentNode("omni_outs_ptr"),
                                        newIdentNode("omni_audio_channel")
                                    ),
                                    newIdentNode("omni_audio_index")
                                ),
                                newFloatLitNode(0.0)
                            )
                        )
                    )
                )
            )
        )

        release_omni_buffers_lock = nnkCall.newTree(
            newIdentNode("releaseBufferLock"),
            nnkDotExpr.newTree(
                newIdentNode("omni_ugen"),
                newIdentNode("omni_buffers_lock")
            )
        )

        lock_buffer_if = nnkIfStmt.newTree(
            nnkElifBranch.newTree(
                newEmptyNode(), #this will be replaced  
                nnkStmtList.newTree(
                    silence,
                    nnkCall.newTree(
                        newIdentNode("omni_unlock_buffers")
                    ),
                    release_omni_buffers_lock,
                    nnkReturnStmt.newTree(
                        newEmptyNode()
                    )
                )
            )
        )

        lock_buffers_stmt = nnkStmtList.newTree(
            lock_buffer_if
        )

        lock_buffers_acquire = nnkElifBranch.newTree(
            nnkCall.newTree(
                newIdentNode("acquireBufferLock"),
                nnkDotExpr.newTree(
                    newIdentNode("omni_ugen"),
                    newIdentNode("omni_buffers_lock")
                )
            ),
            nnkStmtList.newTree(
                lock_buffers_stmt,
                nnkCall.newTree(
                    newIdentNode("releaseBufferLock"),
                    nnkDotExpr.newTree(
                        newIdentNode("omni_ugen"),
                        newIdentNode("omni_buffers_lock")
                    )
                )
            )
        )

        lock_buffers_if = nnkIfStmt.newTree(
            lock_buffers_acquire,
            nnkElse.newTree(
                nnkStmtList.newTree(
                    silence,
                    nnkReturnStmt.newTree(
                        newEmptyNode()
                    )
                )
            )
        )

        lock_buffers_body = nnkStmtList.newTree(
            lock_buffers_if
        )

        lock_buffers_template = nnkTemplateDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("omni_lock_buffers")
            ),
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
                nnkWhenStmt.newTree(
                    nnkElifBranch.newTree(
                        newIdentNode("omni_at_least_one_buffer"),
                        lock_buffers_body
                    )
                )
            )
        )

    #just one buffer
    if omni_buffers_names_list.len == 1:
        let 
            buffer_ident = newIdentNode(omni_buffers_names_list[0])
            buf_lock = nnkPrefix.newTree(
                newIdentNode("not"),
                nnkDotExpr.newTree(
                    buffer_ident,
                    newIdentNode("omni_lock_buffer")
                )
            )
            buf_unlock = nnkCall.newTree(
                newIdentNode("omni_unlock_buffer"),
                buffer_ident
            )
        
        lock_buffer_if[0][0]  = buf_lock

        unlock_buffers_body.add(
            buf_unlock
        )

    #multiple buffers
    elif omni_buffers_names_list.len > 1:
        var 
            lock_buffer_str  : string

        for i, buffer_name in omni_buffers_names_list:
            let buffer_ident = newIdentNode(buffer_name)

            unlock_buffers_body.add(
                nnkCall.newTree(
                    newIdentNode("omni_unlock_buffer"),
                    buffer_ident
                )
            )

            #I'm lazy. not gonna do the "or" infix business, gonna use parseStmt later
            if i == 0:
                lock_buffer_str = "(not omni_lock_buffer(" & buffer_name & ")) or " 
            else:
                lock_buffer_str.add("(not omni_lock_buffer(" & buffer_name & ")) or ")

            #remove last " or"
            if i == (omni_buffers_names_list.len - 1):
                lock_buffer_str  = lock_buffer_str[0..lock_buffer_str.len - 5]

        #Parse the not(lock_buffer(buf)) or not(lock_buffer(buf2)) ...etc..
        lock_buffer_if[0][0] = parseStmt(lock_buffer_str)[0]

    else:
        lock_buffers_body[0] = nnkDiscardStmt.newTree(
            newEmptyNode()
        )

        unlock_buffers_body = nnkDiscardStmt.newTree(
            newEmptyNode()
        )

    result.add(
        unlock_buffers_template,
        lock_buffers_template
    )

    #error repr result

#For buffers[0] syntax
proc omni_buffers_generate_get_dynamic_buffer() : NimNode {.compileTime.} =
    result = nnkStmtList.newTree()
    
    if omni_buffers_names_list.len > 0:
        var 
            if_stmt = nnkIfStmt.newTree()
            first_buffer_str : string
            first_buffer_ident : NimNode
        
        result.add(
            newProc(
                nnkPostfix.newTree(
                    newIdentNode("*"),
                    newIdentNode("omni_get_dynamic_buffer")
                ),
                [ 
                    newIdentNode("untyped"),
                    nnkIdentDefs.newTree(
                        newIdentNode("index"),
                        newIdentNode("SomeInteger"),
                        newLit(0)
                    )
                ],
                pragmas = nnkPragma.newTree(
                    newIdentNode("dirty")
                ),
                body = nnkStmtList.newTree(
                    if_stmt
                ),
                procType = nnkTemplateDef
            )
        )

        for index, buffer_name in omni_buffers_names_list:
            var buffer_ident = newIdentNode(buffer_name)
            if index == 0:
                first_buffer_str = buffer_name
                first_buffer_ident = buffer_ident
            if_stmt.add(
                nnkElifBranch.newTree(
                    nnkInfix.newTree(
                        newIdentNode("=="),
                        nnkCall.newTree(
                            newIdentNode("int"),
                            newIdentNode("index")
                        ),
                        newLit(index)
                    ),
                    buffer_ident
                )
            )
        
        if_stmt.add(
            nnkElse.newTree(
                nnkStmtList.newTree(
                    nnkCall.newTree(
                        newIdentNode("omni_print_str"),
                        newLit("ERROR: omni_get_dynamic_buffer: trying to access out of bounds Buffer. The first Buffer, '" & first_buffer_str & "', will be returned instead.")
                    ),
                first_buffer_ident
                )
            )
        )

    #error repr result

macro omni_buffers_inner*(buffers_number : typed, buffers_names : untyped) : untyped =
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
        omni_at_least_one_buffer = true

    elif buffers_number_VAL == 0:
        buffers_number_VAL = 1
        zero_buffers = true
    
    elif buffers_number_VAL < 0:
        error("buffers: Expected a positive number for buffers number")

    var statement_counter = 0

    #This is for the buffers 1, buf case. (where buf is not viewed as varargs)
    if buffers_names_kind == nnkIdent:
        if zero_buffers:
            error("buffers: Can't assign names when declaring 0 buffers.")
        let buffer_name = buffers_names.strVal()
        omni_check_valid_name(buffer_name, "buffers")
        buffers_names_string.add($buffer_name & ",")
        omni_buffers_names_list.add(buffer_name)
        buffer_defaults.add(OMNI_DEFAULT_NIL_BUFFER)
        statement_counter = 1

    #block case
    else:
        #multiple statements: "freq" {440} OR "freq" {0, 22000} OR "freq" {0 22000} OR "freq" {440, 0, 22000} OR "freq" {440 0 22000}
        if buffers_names_kind == nnkStmtList:
            if zero_buffers:
                error("buffers: Can't assign names when declaring 0 buffers.")
            for statement in buffers_names.children():
                let statement_kind = statement.kind

                #buf
                if statement_kind == nnkIdent:
                    let buffer_name = statement.strVal()
                    omni_check_valid_name(buffer_name, "buffers")
                    buffers_names_string.add($buffer_name & ",")
                    omni_buffers_names_list.add(buffer_name)
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
                    omni_check_valid_name(buffer_name, "buffers")
                    buffers_names_string.add($buffer_name & ",")
                    omni_buffers_names_list.add(buffer_name)

                    if buffer_default_kind != nnkStrLit:
                        error("buffers: Buffer '" & $buffer_name & "' must have a string literal as default value.")

                    let buffer_default_name = buffer_default.strVal()
                    if buffer_default_name == OMNI_DEFAULT_NIL_BUFFER or buffer_default_name == OMNI_NIL:
                        error("buffers: the '" & OMNI_DEFAULT_NIL_BUFFER & "' name is reserved")
                    buffer_defaults.add(buffer_default_name)

                else:
                    error("buffers: Invalid syntax: '" & $(repr(statement)) & "'")

                statement_counter += 1
                    
        elif buffers_names_kind == nnkCommand:
            error("buffers: command syntax not implemented yet")

    #buffers count mismatch
    if not zero_buffers:
        if buffers_names_kind == nnkNilLit:
            for i in 0..buffers_number_VAL-1:
                let buffer_name = "buf" & $(i + 1)
                buffers_names_string.add(buffer_name & ",")
                omni_buffers_names_list.add(buffer_name)
        else:
            if statement_counter != buffers_number_VAL:
                error("buffers: Expected " & $buffers_number_VAL & " buffer names, got " & $statement_counter)

        #Remove trailing coma
        if buffers_names_string.len > 1:
            buffers_names_string.removeSuffix(',')

    #Assign to node
    buffers_names_node = newLit(buffers_names_string)

    #Mismatch with defaults
    if buffers_number_VAL > buffer_defaults.len:
        for i in 0..<buffers_number_VAL:
            buffer_defaults.add(OMNI_DEFAULT_NIL_BUFFER)

    let
        omni_buffers_generate_defaults = omni_buffers_generate_defaults(buffer_defaults)
        omni_buffers_generate_set_templates = omni_buffers_generate_set_templates()
        omni_buffers_generate_unpack_templates = omni_buffers_generate_unpack_templates()
        omni_buffers_generate_get_dynamic_buffer = omni_buffers_generate_get_dynamic_buffer()
        omni_generate_lock_unlock_buffers = omni_generate_lock_unlock_buffers()
    
    var omni_when_declared_buffer_wrapper_interface : NimNode

    if zero_buffers:
        buffers_number_VAL = 0
        buffers_names_node = newLit(OMNI_NIL)
        omni_when_declared_buffer_wrapper_interface = nnkDiscardStmt.newTree(
            newEmptyNode()
        )
    else:
        omni_when_declared_buffer_wrapper_interface = nnkWhenStmt.newTree(
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
                            newLit("buffers: no 'Buffer' interface provided. This must come from an Omni wrapper.")
                        )
                    )
                )
            )
        )
    
    return quote do:
        when not declared(omni_declared_buffers):
            #Check buffer interface
            `omni_when_declared_buffer_wrapper_interface`
            
            #declare global vars
            const  
                omni_buffers             {.inject.}  = `buffers_number_VAL`  
                buffers                  {.inject.}  = omni_buffers         #Better alias to use in omni code
                omni_buffers_names_const {.inject.}  = `buffers_names_node` #Used for omni_io.txt 

            #compile time variable if buffers are defined
            let omni_declared_buffers {.inject, compileTime.} = true

            #Returns a const with default names and a template that calls the default init names (to be called in init)
            `omni_buffers_generate_defaults`

            #Returns a template that generates all setbuffers procs. This must be called after Omni_UGen definition
            `omni_buffers_generate_set_templates`

            #Returns a template that generates the unpacking of buffers for perform block
            `omni_buffers_generate_unpack_templates`
            
            #Returns a proc for dynamic accessing of buffers with buffers[..] syntax
            `omni_buffers_generate_get_dynamic_buffer`

            #Create omni_lock_buffers and omni_unlock_buffers templates
            #omni_unlock_buffers is generated first because it's used in omni_lock_buffers to unlock all buffers in case of error in locking one
            `omni_generate_lock_unlock_buffers`

            #Export to C
            proc Omni_UGenBuffers() : int32 {.exportc: "Omni_UGenBuffers", dynlib.} =
                return int32(omni_buffers)

            proc Omni_UGenBuffersNames() : ptr cchar {.exportc: "Omni_UGenBufferNames", dynlib.} =
                return cast[ptr cchar](omni_buffers_names_const)
            
            proc Omni_UGenBuffersDefaults() : ptr cchar {.exportc: "Omni_UGenBufferDefaults", dynlib.} =
                return cast[ptr cchar](omni_buffers_defaults_const_unpacked) #used the unpacked version (single string)
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
        omni_buffers_inner(`buffers_number`, `buffers_names`)

#bufs == buffers
macro bufs*(args : varargs[untyped]) : untyped =
    return quote do:
        buffers(`args`)
