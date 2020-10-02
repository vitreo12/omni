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

let 
    #These are all the types that a var declaration support
    varDeclTypes* {.compileTime.} = [
        "bool", 
        "enum",
        "tuple",
        "float", "float32", "float64",
        "cfloat", "cdouble",
        "int", "int32", "int64",
        "cint", "clong",
        "uint", "uint32", "uint64",
        "sig", "sig32", "sig64",
        "signal", "signal32", "signal64"
    ]

    #These are additional types that function arguments support
    additionalArgDeclTypes* {.compileTime.} = [
        "auto",
        "pointer",
        "typeDesc",
        "OmniAutoMem",
        "UGen"
    ]

    #These are additional types that function calls support. Add support for string and cstring (to make print("hello") work)
    additionalArgCallTypes* {.compileTime.} = [
        "string",
        "cstring"
    ]


proc isStruct*(var_type : NimNode) : bool {.compileTime.} =        
    #if not is_struct_field:
    let 
        type_tree = var_type.getTypeImpl()
        type_tree_kind = type_tree.kind

    if type_tree_kind == nnkSym:
        let type_tree_str = type_tree.strVal()
        if type_tree_str.endsWith("_struct_inner") or type_tree_str.endsWith("_struct_export"):
            return true

    elif type_tree_kind == nnkBracketExpr or type_tree_kind == nnkPtrTy:
        var 
            type_inner = type_tree[0]
            type_inner_kind = type_inner.kind
        
        if type_inner_kind == nnkBracketExpr:
            type_inner = type_inner[0]
            type_inner_kind = type_inner.kind

        if type_inner_kind == nnkSym:
            let type_inner_str = type_inner.strVal()

            #First arg of defs (obj_type)... Run on the enclosing paranthesis typedesc[Phasor]
            if type_inner_str == "typeDesc":
                return isStruct(type_tree[1])

            elif type_inner_str.endsWith("_struct_inner") or type_inner_str.endsWith("_struct_export"):
                return true
    
    return false


#Check type validity. This requires var_type to be a typed one. (it's either caled by the macro below or in the typed static analysis in omni_parser.nim)
proc checkValidType*(var_type : NimNode, var_name : string = "", is_proc_arg : bool = false, is_proc_call : bool = false, is_struct_field : bool = false, proc_name : string = "", is_tuple_entry : bool = false) : void {.compileTime.} =
    var var_type_str : string

    let var_type_kind = var_type.kind

    #Bracket expr (seq / array), pointer (structs / ptr ...), extract the actual name
    if var_type_kind == nnkBracketExpr or var_type_kind == nnkPtrTy or var_type_kind == nnkRefTy:
        let var_type_inner = var_type[0]
        
        #struct with generics
        if var_type_inner.kind == nnkBracketExpr:
            var_type_str = var_type_inner[0].strVal()
        #no generics
        else:
            var_type_str = var_type[0].strVal()
    
    #tuples
    elif var_type_kind == nnkTupleConstr or var_type_kind == nnkPar:
        #check all entries of the tuple too
        for tuple_entry_type in var_type:
            checkValidType(tuple_entry_type, var_name, is_proc_arg, is_proc_call, is_struct_field, proc_name, true)

        var_type_str = "tuple"
    
    #idents / syms
    elif var_type_kind == nnkIdent or var_type_kind == nnkSym:
        var_type_str = var_type.strVal()

    else:
        error "Type checker: invalid kind '" & $var_type_kind & "'"

    #echo "checkValidType"
    #echo astGenRepr var_type

    #proc call
    if is_proc_call:
        #If arg to a proc call, it should accept strings/cstrings too! 
        if not ((var_type_str in varDeclTypes) or (var_type_str in additionalArgDeclTypes) or (var_type_str in additionalArgCallTypes) or (var_type.isStruct())):
            var proc_name_real : string
            if proc_name.endsWith("_def_inner"):
                proc_name_real = proc_name[0..(proc_name.len - 11)] #remove _def_inner
            else:
                proc_name_real = proc_name
            error("Call to \'" & $proc_name_real & "\' : argument number " & $var_name & " is of unknown type: \'" & $var_type & "\'.")
    
    #proc argument (static)
    elif is_proc_arg:
        if not ((var_type_str in varDeclTypes) or (var_type_str in additionalArgDeclTypes) or (var_type.isStruct())):
            error("\'def " & $proc_name & "\' : argument \'" & $var_name & "\' is of unknown type: \'" & $var_type_str & "\'.")

    #struct field
    elif is_struct_field:
        if not ((var_type_str in varDeclTypes) or (var_type_str in additionalArgDeclTypes) or (var_type.isStruct())):
            error("\'struct " & $proc_name & "\' : field \'" & $var_name & $ "\' contains unknown type: \'" & $var_type_str & "\'.")

    #tuple field
    elif is_tuple_entry:
        if not ((var_type_str in varDeclTypes)):
            error("tuple '" & $var_name & "' contains an invalid type: '" & $var_type_str & "'. Tuples only support number types.")

    #variable declaration
    else:
        if not ((var_type_str in varDeclTypes) or (var_type.isStruct())):
            error("\'" & $var_name & "\' is of unknown type: \'" & $var_type_str & "\'.")

        
#This is used for def's argument type checking
#The trick here is the var_type : typed, which will hold all of its type structure when running it through isStruct in checkValidType
macro checkValidType_macro*(var_type : typed, var_name : typed = "", is_proc_arg : typed, is_proc_call : typed, is_struct_field : typed, proc_name : typed = "") : void =
    
    var 
        var_name_str = var_name.strVal()
        is_proc_arg_bool = is_proc_arg.boolVal()
        is_proc_call_bool = is_proc_call.boolVal()
        is_struct_field_bool = is_struct_field.boolVal()
        proc_name_str = proc_name.strVal()

    checkValidType(var_type, var_name_str, is_proc_arg_bool, is_proc_call_bool, is_struct_field_bool, proc_name_str)