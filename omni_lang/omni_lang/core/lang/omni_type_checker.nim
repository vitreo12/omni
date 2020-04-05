import macros, strutils

let 
    #These are all the types that a var declaration support
    varDeclTypes* {.compileTime.} = [
        "array",
        "bool", 
        "enum",
        "float", "float32", "float64",
        "int", "int32", "int64",
        "uint", "uint32", "uint64",
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
    
    let type_tree = var_type.getType()
    
    assert type_tree.len == 2

    #echo "isStruct"
    #echo astGenRepr var_type

    let 
        #type_tree_kind = type_tree.kind 
        inner_type_tree = type_tree[1]
        inner_type_tree_kind = inner_type_tree.kind
    
    if inner_type_tree_kind == nnkBracketExpr:
        let inner_inner_type_tree = inner_type_tree[1]

        #struct with generics
        if inner_inner_type_tree.kind == nnkBracketExpr:
            if inner_inner_type_tree[0].strVal().endsWith("_obj"):
                return true
        
        #normal struct
        elif inner_type_tree[1].strVal().endsWith("_obj"):
            return true
    
    #not a struct?
    elif inner_type_tree_kind == nnkSym:
        if inner_type_tree.strVal().endsWith("_obj"):
            return true

    return false


#Check type validity. This requires var_type to be a typed one. (it's either caled by the macro below or in the typed static analysis in omni_parser.nim)
proc checkValidType*(var_type : NimNode, var_name : string = "", is_proc_arg : bool = false, is_proc_call : bool = false, proc_name : string = "") : void {.compileTime.} =
    var var_type_str : string

    #Bracket expr (seq / array), pointer (structs / ptr ...), extract the actual name
    if var_type.kind == nnkBracketExpr or var_type.kind == nnkPtrTy:
        let var_type_inner = var_type[0]
        
        #struct with generics
        if var_type_inner.kind == nnkBracketExpr:
            var_type_str = var_type_inner[0].strVal()
        #no generics
        else:
            var_type_str = var_type[0].strVal()
    
    #standard types
    else:
        var_type_str = var_type.strVal()

    #echo "checkValidType"
    #echo astGenRepr var_type

    #proc call
    if is_proc_call:
        #If arg to a proc call, it should accept strings/cstrings too! 
        if not ((var_type_str in varDeclTypes) or (var_type_str in additionalArgDeclTypes) or (var_type_str in additionalArgCallTypes) or (var_type.isStruct())):
            var proc_name_real : string
            if proc_name.endsWith("_inner"):
                proc_name_real = proc_name[0..(proc_name.len - 7)] #remove _inner
            else:
                proc_name_real = proc_name
            error("Call to \"" & $proc_name_real & "\" : argument number " & $var_name & " is of unsupported type: \"" & $var_type & "\".")
    
    #proc argument (static)
    elif is_proc_arg:
        if not ((var_type_str in varDeclTypes) or (var_type_str in additionalArgDeclTypes) or (var_type.isStruct())):
            error("\"def " & $proc_name & "\" : argument \"" & $var_name & "\" is of unsupported type: \"" & $var_type_str & "\".")

    #variable declaration
    else:
        if not ((var_type_str in varDeclTypes) or (var_type.isStruct())):
            error("\"" & $var_name & "\" is of unsupported type: \"" & $var_type_str & "\".")
        

#This is used for def's argument type checking
#The trick here is the var_type : typed, which will hold all of its type structure when running it through isStruct in checkValidType
macro checkValidType_macro*(var_type : typed, var_name : typed = "", is_proc_arg : typed, is_proc_call : typed, proc_name : typed = "") : void =
    
    var 
        var_name_str = var_name.strVal()
        is_proc_arg_bool = is_proc_arg.boolVal()
        is_proc_call_bool = is_proc_call.boolVal()
        proc_name_str = proc_name.strVal()

    checkValidType(var_type, var_name_str, is_proc_arg_bool, is_proc_call_bool, proc_name_str)