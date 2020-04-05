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
    return (var_type.strVal()).endsWith("_obj")

proc isStruct*(var_type : string) : bool {.compileTime.} =
    return var_type.endsWith("_obj")

#Check if it's a valid parsed type!
proc checkValidType*(var_type : NimNode, var_name : string = "", is_proc_arg : bool = false, is_proc_call : bool = false, proc_name : string = "") : void {.compileTime.} =
    var var_type_real : string

    #Bracket expr (seq / array), pointer (structs / ptr ...), extract the actual name
    if var_type.kind == nnkBracketExpr or var_type.kind == nnkPtrTy:
        let var_type_inner = var_type[0]
        
        #struct with generics
        if var_type_inner.kind == nnkBracketExpr:
            var_type_real = var_type_inner[0].strVal()
        #no generics
        else:
            var_type_real = var_type[0].strVal()
    
    #standard types
    else:
        var_type_real = var_type.strVal()

    #proc call
    if is_proc_call :
        #If function arg, it should accept strings/cstrings too! 
        if not ((var_type_real in varDeclTypes) or (var_type_real in additionalArgDeclTypes) or (var_type_real in additionalArgCallTypes) or (var_type_real.isStruct())):
            var proc_name_real : string
            if proc_name.endsWith("_inner"):
                proc_name_real = proc_name[0..(proc_name.len - 7)] #remove _inner
            else:
                proc_name_real = proc_name
            error("Call to \"" & $proc_name_real & "\" : argument number " & $var_name & " is of unsupported type: \"" & $var_type_real & "\".")
    
    #proc argument
    elif is_proc_arg:
        if not ((var_type_real in varDeclTypes) or (var_type_real in additionalArgDeclTypes) or (var_type_real.isStruct())):
            error("\"def " & $proc_name & "\" : argument \"" & $var_name & "\" is of unsupported type: \"" & $var_type_real & "\".")

    #variable
    else:
        if not ((var_type_real in varDeclTypes) or (var_type_real.isStruct())):
            error("\"" & $var_name & "\" is of unsupported type: \"" & $var_type_real & "\".")
        
    