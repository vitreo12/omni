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

import macros, strutils, tables, omni_invalid, omni_type_checker, omni_macros_utilities

const valid_struct_generics = [
    "int", "int32", "int64",
    "float", "float32", "float64",
    "signal", "signal32", "signal64",
    "sig", "sig32", "sig64"
]


proc find_data_bracket_bottom(statement : NimNode, how_many_datas : var int) : NimNode {.compileTime.} =
    if statement.kind == nnkBracketExpr:
        let statement_ident = statement[0]
        if statement_ident.kind == nnkIdent or statement_ident.kind == nnkSym:
            let statement_ident_str = statement_ident.strVal()
            #Data, keep searching
            if statement_ident_str == "Data" or statement_ident_str == "Data_struct_export":
                how_many_datas += 1
                return find_data_bracket_bottom(statement[1], how_many_datas)
            else:
                error("Invalid type: '" & repr(statement) & "'")
    
    elif statement.kind == nnkSym:
        let 
            type_impl = statement.getImpl()

        #in-built types
        if type_impl.kind == nnkNilLit:
            return statement
            
        let
            type_name = type_impl[0]
            type_generics = type_impl[1]

        var final_stmt = nnkBracketExpr.newTree(
            type_name
        )

        #Add float instead of generic. Should it be sig/signal instead?
        if type_generics.kind == nnkGenericParams:
            for type_generic in type_generics:
                final_stmt.add(
                    newIdentNode("float")
                )
        
        #Ok, nothing to do here. use the original one
        else:
            return nil

        #Add the Data count back
        if how_many_datas > 0:
            for i in 0..how_many_datas-1:
                final_stmt = nnkBracketExpr.newTree(
                    newIdentNode("Data"),
                    final_stmt
                )

        return final_stmt
    
    return statement

#var_names stores pairs in the form [name, 0] for untyped, [name, 1] for typed
#fields_untyped are all the fields that have generics in them
#fields_typed are the fields that do not have generics, and need to be tested to find if they need a "signal" generic initialization
macro declare_struct*(obj_type_def : untyped, ptr_type_def : untyped, export_type_def : untyped, var_names : untyped, fields_untyped : untyped, fields_typed : varargs[typed]) : untyped =
    var 
        final_stmt_list = nnkStmtList.newTree()          #return statement
        type_section    = nnkTypeSection.newTree()       #the whole type section (both struct_inner and ptr)
        obj_ty          = nnkObjectTy.newTree(
            newEmptyNode(),
            newEmptyNode()
        )

        rec_list        = nnkRecList.newTree()           #the variable declaration section of Phasor_struct_inner

    var
        untyped_counter = 0
        typed_counter   = 0

    var fields_typed_to_signal_generics : seq[NimNode]

    for field_typed in fields_typed:
        var 
            how_many_datas = 0
            field_typed_to_signal_generics = find_data_bracket_bottom(field_typed, how_many_datas)

        #Keep the normal one if nil returned 
        if field_typed_to_signal_generics == nil:
            field_typed_to_signal_generics = field_typed
        
        fields_typed_to_signal_generics.add(field_typed_to_signal_generics)
    
    #Get untyped / typed variables and add them to obj_ty
    for var_name_bool in var_names:
        let 
            var_name = var_name_bool[0]
            var_bool = var_name_bool[1].boolVal()

        var var_type : NimNode
        
        #Untyped
        if var_bool:
            var_type = fields_untyped[untyped_counter]
            untyped_counter += 1
        
        #Typed
        else:
            var_type = fields_typed_to_signal_generics[typed_counter]
            typed_counter += 1

        var new_decl = nnkIdentDefs.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                var_name
            ),
            var_type,
            newEmptyNode()
        )
        

        rec_list.add(new_decl)

    #Add var : type declarations to obj declaration
    obj_ty.add(rec_list)
    
    #Add the obj declaration (the nnkObjectTy) to the type declaration
    obj_type_def.add(obj_ty)
    
    #Add the type declaration of Phasor_struct_inner to the type section
    type_section.add(obj_type_def)
    
    #Add the type declaration of Phasor to type section
    type_section.add(ptr_type_def)

    #Add the type declaration of Phasor_struct_export
    type_section.add(export_type_def)

    #Add the whole type section to result
    final_stmt_list.add(type_section)

    #error astgenrepr final_stmt_list
    #echo repr final_stmt_list

    return quote do:
        `final_stmt_list`

#Check if a struct field contains generics
proc untyped_or_typed(var_type : NimNode, generics_seq : seq[NimNode]) : bool {.compileTime.} =
    if var_type.kind == nnkBracketExpr:
        let var_type_ident = var_type[0]
        if var_type_ident.kind == nnkIdent:
            let var_type_ident_str = var_type_ident.strVal()
            #Data, keep searching
            if var_type_ident_str == "Data" or var_type_ident_str == "Data_struct_export":
                return untyped_or_typed(var_type[1], generics_seq)
            
            #Normal bracket expr like Phasor[T] or Phasor[int]
            else:
                return true
    
    #Bottom of the search
    elif var_type.kind == nnkIdent:
        if (var_type.strVal() in valid_struct_generics) or (var_type in generics_seq):
            return true  

    return false 

proc add_to_checkValidTypes_macro_and_check_struct_fields_generics(statement : NimNode, var_name : NimNode, ptr_name : NimNode, generics_seq : seq[NimNode], checkValidTypes : NimNode) : void {.compileTime.} =
    if statement.kind == nnkBracketExpr:
        let 
            var_name_str = var_name.strVal()
            ptr_name_str = ptr_name.strVal()

        var already_looped = false

        #Check validity of structs that are not Datas
        if statement[0].strVal() != "Data" and statement[0].strVal() != "Data_struct_export":
            already_looped = true
            for index, entry in statement:
                if index == 0:
                    continue
                
                if entry.kind != nnkIdent and entry.kind != nnkSym:
                    error("'struct " & ptr_name_str & "': invalid field '" & var_name_str &  "': it contains invalid type '" & repr(statement) & "'")
                
                let entry_str = entry.strVal()
                if (not (entry_str in valid_struct_generics)) and (not(entry in generics_seq)):
                    error("'struct " & ptr_name_str & "': invalid field '" & var_name_str &  "': it contains invalid type '" & repr(statement) & "'")
                
                add_to_checkValidTypes_macro_and_check_struct_fields_generics(entry, var_name, ptr_name, generics_seq, checkValidTypes)
                
                if not(entry in generics_seq):
                    checkValidTypes.add(
                        nnkCall.newTree(
                            newIdentNode("checkValidType_macro"),
                            entry,
                            newLit(var_name_str), 
                            newLit(false),
                            newLit(false),
                            newLit(true),
                            newLit(ptr_name_str)
                        )
                    )

        if not already_looped:
            for entry in statement:
                add_to_checkValidTypes_macro_and_check_struct_fields_generics(entry, var_name, ptr_name, generics_seq, checkValidTypes)
                
                if entry.kind == nnkIdent or entry.kind == nnkSym:
                    if not(entry in generics_seq):
                        checkValidTypes.add(
                            nnkCall.newTree(
                                newIdentNode("checkValidType_macro"),
                                entry,
                                newLit(var_name_str), 
                                newLit(false),
                                newLit(false),
                                newLit(true),
                                newLit(ptr_name_str)
                            )
                        )

#Entry point for struct
macro struct*(struct_name : untyped, code_block : untyped) : untyped =
    var 
        obj_type_def    = nnkTypeDef.newTree()           #the Phasor_struct_inner block

        ptr_type_def    = nnkTypeDef.newTree()           #the Phasor = ptr Phasor_struct_inner block
        ptr_ty          = nnkPtrTy.newTree()             #the ptr type expressing ptr Phasor_struct_inner
        
        export_type_def : NimNode

        generics_seq : seq[NimNode]
        checkValidTypes = nnkStmtList.newTree()        #Check that types fed to struct are correct omni types
    
    var 
        obj_name : NimNode
        ptr_name : NimNode
        export_name : NimNode

        generics = nnkGenericParams.newTree()          #If generics are present in struct definition

        obj_bracket_expr : NimNode

    var
        var_names      = nnkStmtList.newTree()
        fields_untyped = nnkStmtList.newTree()
        fields_typed   : seq[NimNode]

    var struct_name_str : string

    #Using generics
    if struct_name.kind == nnkBracketExpr:
        struct_name_str = struct_name[0].strVal()
        
        obj_name = newIdentNode(struct_name_str & "_struct_inner")  #Phasor_struct_inner
        export_name = newIdentNode(struct_name_str & "_struct_export")
        ptr_name = struct_name[0]                                     #Phasor

        #If struct name doesn't start with capital letter, error out
        if not(ptr_name.strVal[0] in {'A'..'Z'}):
            error("struct \"" & $ptr_name & $ "\" must start with a capital letter")

        #NOTE THE DIFFERENCE BETWEEN obj_type_def here with generics and without, different number of newEmptyNode()
        #Add name to obj_type_def (with asterisk, in case of supporting modules in the future)
        obj_type_def.add(
            nnkPostfix.newTree(
                newIdentNode("*"),
                obj_name
            )
        )

        #NOTE THE DIFFERENCE BETWEEN ptr_type_def here with generics and without, different number of newEmptyNode()
        #Add name to ptr_type_def (with asterisk, in case of supporting modules in the future)
        ptr_type_def.add(
            nnkPostfix.newTree(
                newIdentNode("*"),
                ptr_name
            )
        )

        #Initialize them to be bracket expressions and add the "Phasor_struct_inner" and "Phasor" names to brackets
        obj_bracket_expr = nnkBracketExpr.newTree(
            obj_name
        )
        #ptr_bracket_expr = nnkBracketExpr.newTree(
        #    ptr_name
        #)

        for index, child in struct_name:
            if index == 0:
                continue
            else:
                var generic_proc = nnkIdentDefs.newTree()
                    
                #If singular [T]
                if child.len() == 0:
                    ##Also add the name of the generic to the Phasor_struct_inner[T, Y...]
                    obj_bracket_expr.add(child)

                    #Also add the name of the generic to the Phasor[T, Y...]
                    #ptr_bracket_expr.add(child)

                    generic_proc.add(
                        child,
                        newEmptyNode(),
                        newEmptyNode()
                    )

                    generics.add(generic_proc)

                    generics_seq.add(child)

                #If [T : Something etc...]
                else:
                    error("\'" & $ptr_name.strVal() & $ "\'s generic type \'" & $(child[0].strVal()) & "\' contains subtypes. These are not supported.")
        
        #Add generics to obj type
        obj_type_def.add(generics)

        #Add generics to ptr type
        ptr_type_def.add(generics)

        #Add the Phasor_struct_inner[T, Y] to ptr_ty, for object that the pointer points at.
        ptr_ty.add(obj_bracket_expr)

    #No generics, just name of struct
    elif struct_name.kind == nnkIdent:
        struct_name_str = struct_name.strVal()
        
        obj_name = newIdentNode(struct_name_str & "_struct_inner")              #Phasor_struct_inner
        export_name = newIdentNode(struct_name_str & "_struct_export") 
        ptr_name = struct_name                                        #Phasor

        #If struct name doesn't start with capital letter, error out
        if not(ptr_name.strVal[0] in {'A'..'Z'}):
            error("struct \"" & $ptr_name & $ "\" must start with a capital letter")
        
        #Add name to obj_type_def. Needs to be exported for proper working!
        obj_type_def.add(
            nnkPostfix.newTree(
                newIdentNode("*"),
                obj_name
            ),
            newEmptyNode()
        )

        #Add name to ptr_type_def.
        ptr_type_def.add(
            nnkPostfix.newTree(
                newIdentNode("*"),
                ptr_name
            ),
            newEmptyNode()
        )

        #Add the Phasor_struct_inner[T, Y] to ptr_ty, for object that the pointer points at.
        ptr_ty.add(obj_name)

        #When not using generics, the sections where the bracket generic expression is used are just the normal name of the type
        obj_bracket_expr = obj_name
        #ptr_bracket_expr = ptr_name

    #Detect invalid struct name
    if struct_name_str in omni_invalid_idents:
        error("Trying to redefine in-build struct '" & struct_name_str & "'")

    #Detect invalid ends with
    for invalid_ends_with in omni_invalid_ends_with:
        if struct_name_str.endsWith(invalid_ends_with):
            error("struct names can't end with '" & invalid_ends_with & "': it's reserved for internal use.")

    #Loop over struct's body
    for code_stmt in code_block:
        let code_stmt_kind = code_stmt.kind

        var 
            var_name : NimNode
            var_type : NimNode

        #NO type defined, default it to float
        if code_stmt_kind == nnkIdent:
            var_name = code_stmt
            var_type = newIdentNode("float")

        #phase float
        if code_stmt_kind == nnkCommand:
            assert code_stmt.len == 2
            assert code_stmt[0].kind == nnkIdent
            
            #This is needed for generics!
            if code_stmt[1].kind != nnkIdent:
                if code_stmt[1].kind != nnkBracketExpr:
                    error("\"" & $ptr_name & "\": " & "Invalid struct body")

            var_name = code_stmt[0]
            var_type = code_stmt[1]

        #phase : float
        elif code_stmt_kind == nnkCall:
            
            #Have some better error checking and printing here
            if code_stmt.len != 2 or code_stmt[0].kind != nnkIdent or code_stmt[1].kind != nnkStmtList or code_stmt[1][0].kind != nnkIdent:

                #Needed for generics in body of struct
                if code_stmt[1][0].kind != nnkBracketExpr:
                    error("\"" & $ptr_name & "\": " & "Invalid struct body")
        
            var_name = code_stmt[0]
            var_type = code_stmt[1][0]

        var var_type_untyped_or_typed = false

        var_type_untyped_or_typed = untyped_or_typed(var_type, generics_seq)

        add_to_checkValidTypes_macro_and_check_struct_fields_generics(var_type, var_name, ptr_name, generics_seq, checkValidTypes)

        if var_type_untyped_or_typed:
            var_names.add(
                nnkBracketExpr.newTree(
                    var_name,
                    newLit(true)
                )
            )
                
            fields_untyped.add(var_type)
        else:
            var_names.add(
                nnkBracketExpr.newTree(
                    var_name,
                    newLit(false)
                )
            )

            fields_typed.add(var_type)

    #Add the ptr_ty inners to ptr_type_def, so that it is completed when sent to declare_struct
    ptr_type_def.add(ptr_ty)

    #Build the Phasor_struct_export out of the ptr
    export_type_def = ptr_type_def.copy()
    export_type_def[0][1] = export_name
    export_type_def[^1] = export_type_def.last()[0]

    #Generics
    if export_type_def.last().kind == nnkBracketExpr:
        export_type_def[^1][0] = ptr_name
    else:
        export_type_def[^1] = ptr_name

    #error repr export_type_def

    #The init_struct macro, which will declare the "proc struct_new_inner ..." and the "template new ..."
    let struct_create_init_proc_and_template = nnkCall.newTree(
        newIdentNode("struct_create_init_proc_and_template"),
        ptr_name
    )

    let findDatasAndStructs = nnkCall.newTree(
        newIdentNode("findDatasAndStructs"),
        ptr_name
    )

    var declare_struct = nnkCall.newTree(
        newIdentNode("declare_struct"),
        obj_type_def,
        ptr_type_def,
        export_type_def,
        var_names,
        fields_untyped
    )

    for field_typed in fields_typed:
        declare_struct.add(field_typed)

    return quote do:
        `checkValidTypes`
        `declare_struct`
        `struct_create_init_proc_and_template`
        `findDatasAndStructs`

#Declare the "proc struct_new_inner ..." and the "template new ...", doing all sorts of type checks
macro struct_create_init_proc_and_template*(ptr_struct_name : typed) : untyped =
    if ptr_struct_name.kind != nnkSym:
        error("Invalid struct ptr symbol!")

    let 
        ptr_struct_type = ptr_struct_name.getType()
        obj_struct_name = ptr_struct_type[1][1]
        obj_struct_name_kind = obj_struct_name.kind

    let ptr_name = ptr_struct_name.strVal()

    var 
        final_stmt_list = nnkStmtList.newTree()
        obj_struct_type : NimNode
        generics_mapping : OrderedTable[string, NimNode]

    var 
        obj_bracket_expr : NimNode
        ptr_bracket_expr : NimNode

        generics_ident_defs  = nnkStmtList.newTree()     #These are all the generics that will be set to be T : SomeNumber, instead of just T

        proc_def             = nnkProcDef.newTree()      #the struct_new_inner* proc
        proc_formal_params   = nnkFormalParams.newTree() #the whole [T](args..) : returntype 
        proc_body            = nnkStmtList.newTree()     #body of the proc

    #The name of the function with the asterisk, in case of supporting modules in the future
    #proc Phasor_struct_new_inner
    proc_def.add(
        nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode(ptr_name & "_struct_new_inner")
        ),
        newEmptyNode(),
        newEmptyNode()
    )

    #Generics
    if obj_struct_name_kind == nnkBracketExpr:
        let obj_struct_name_ident = obj_struct_name[0]
        obj_struct_type = (obj_struct_name_ident).getTypeImpl()

        #Initialize them to be bracket expressions and add the "Phasor_struct_inner" and "Phasor" names to brackets
        obj_bracket_expr = nnkBracketExpr.newTree(obj_struct_name[0])
        ptr_bracket_expr = nnkBracketExpr.newTree(ptr_struct_name)

        #Retrieve generics
        for index, generic_ident in obj_struct_name.pairs():
            if index == 0:
                continue

            let new_G_generic_ident = newIdentNode("G" & $index)

            ##Also add the name of the generic to the Phasor_struct_inner[T, Y...]
            obj_bracket_expr.add(new_G_generic_ident)

            #Also add the name of the generic to the Phasor[T, Y...]
            ptr_bracket_expr.add(new_G_generic_ident)

            generics_ident_defs.add(
                nnkIdentDefs.newTree(
                    new_G_generic_ident,
                    newIdentNode("typedesc"),
                    nnkBracketExpr.newTree(
                        newIdentNode("typedesc"),
                        newIdentNode("float")
                    )
                )
            )

            #This is needed for comparison later (casting operations)
            generics_mapping[generic_ident.strVal()] = new_G_generic_ident

    #no generics
    else:
        obj_struct_type = obj_struct_name.getTypeImpl()

        #When not using generics, the sections where the bracket generic expression is used are just the normal name of the type
        obj_bracket_expr = obj_struct_name
        ptr_bracket_expr = ptr_struct_name

    #Add Phasor[T, Y] return type
    proc_formal_params.add(ptr_bracket_expr)

    #This is the _struct_export. Don't put the generics in! They will fail some constructors otherwise
    var struct_export_arg =  newIdentNode(ptr_struct_name.strVal() & "_struct_export")

    #Add the when... check for ugen_call_type to see if user is trying to allocate memory in perform!
    proc_body.add(
        nnkWhenStmt.newTree(
            nnkElifBranch.newTree(
                nnkInfix.newTree(
                    newIdentNode("is"),
                    newIdentNode("ugen_call_type"),
                    newIdentNode("PerformCall")
                ),
                nnkStmtList.newTree(
                    nnkPragma.newTree(
                        nnkExprColonExpr.newTree(
                            newIdentNode("fatal"),
                            newLit("attempting to allocate memory in the 'perform' or 'sample' blocks for 'struct " & ptr_name & "'")
                        )
                    )
                )
            )
        )
    )

    #Add the when...for generics type checking
    if generics_ident_defs.len > 0:
        for generic_ident_defs in generics_ident_defs:
            let generic_ident = generic_ident_defs[0]
            proc_body.add(
                nnkWhenStmt.newTree(
                    nnkElifBranch.newTree(
                        nnkInfix.newTree(
                            newIdentNode("isnot"),
                            generic_ident,
                            newIdentNode("SomeNumber")
                        ),
                        nnkStmtList.newTree(
                            nnkPragma.newTree(
                                nnkExprColonExpr.newTree(
                                    newIdentNode("fatal"),
                                    newLit("'" & ptr_name & "': " & $generic_ident.strVal() & " must be some number type.")
                                )
                            )
                        )
                    )
                )
            )

    #Add the allocation of the struct as first entry i n the body of the struct
    proc_body.add(
        nnkAsgn.newTree(
            newIdentNode("result"),
            nnkCast.newTree(
                ptr_bracket_expr,
                nnkCall.newTree(
                        newIdentNode("omni_alloc"),
                        nnkCall.newTree(
                            newIdentNode("culong"),
                                nnkCall.newTree(
                                    newIdentNode("sizeof"),
                                    obj_bracket_expr
                                )
                            )                 
                        )
                )
            )
        )

    #Add "registerChild(ugen_auto_mem, result)"
    proc_body.add(
        nnkCall.newTree(
            newIdentNode("registerChild"),
            newIdentNode("ugen_auto_mem"),
            newIdentNode("result")
        )
    )

    let struct_fields = obj_struct_type[2]

    for index, field in struct_fields:
        assert field.len == 3
        
        var 
            field_name = field[0]
            field_type = field[1]

        var field_type_without_generics = field_type
        
        if field_type.kind == nnkBracketExpr:
            field_type_without_generics = field_type[0]

        let field_type_without_generics_str = field_type_without_generics.strVal()
    
        let 
            field_is_struct  = field_type_without_generics.isStruct()
            field_is_generic = generics_mapping.hasKey(field_type_without_generics_str)
        
        #Use the types without generics, as they are set before the generics are declared.
        #Also, these will be solved when assigning the results... Perhaps I could go with auto anyway?
        #Values are set already in result.a = a
        var 
            arg_field_type  = field_type_without_generics
            arg_field_value = newEmptyNode()
        
        #If field is generic, change T to G1
        if field_is_generic:
            field_type = generics_mapping[field_type_without_generics_str] #retrieve the nim node at the key

        #Always have auto params. The typing will be checked in the body anyway.
        #This solves a lot of problems with generic parameters, and still works (even with structs)
        arg_field_type = newIdentNode("auto")

        #if no struct, go with auto and have value 0
        if not field_is_struct:
            #arg_field_type = newIdentNode("auto")
            arg_field_value = newIntLitNode(0)    

        #Add to arg list for struct_new_inner proc
        proc_formal_params.add(
            nnkIdentDefs.newTree(
                field_name,
                arg_field_type,
                arg_field_value
            )
        )

        #Add result.phase = phase, etc... assignments... Don't cast
        if field_is_struct:
            proc_body.add(
                nnkAsgn.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("result"),
                        field_name
                    ),
                    field_name
                )
            )

        #If it's not a struct, convert the value too (so that generics and types are applied)
        else:
            proc_body.add(
                nnkAsgn.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("result"),
                        field_name
                    ),
                    nnkCall.newTree(
                        field_type,
                        field_name
                    )
                )
            )

    # ===================== #
    # STRUCT_NEW_INNER PROC  #
    # ===================== #

    #Add generics
    if generics_ident_defs.len > 0:
        for generic_ident_defs in generics_ident_defs:
            proc_formal_params.add(generic_ident_defs)

    #Add obj_type
    proc_formal_params.add(
        nnkIdentDefs.newTree(
            newIdentNode("obj_type"),
            nnkBracketExpr.newTree(
                newIdentNode("typedesc"),
                struct_export_arg
            ),
            newEmptyNode()
        )   
    )
    
    #Add ugen_auto_mem : ptr OmniAutoMem argument
    proc_formal_params.add(
        nnkIdentDefs.newTree(
            newIdentNode("ugen_auto_mem"),
            nnkPtrTy.newTree(
                newIdentNode("OmniAutoMem")
            ),
            newEmptyNode()
        )
    )

    #Add ugen_call_type as last argument
    proc_formal_params.add(
        nnkIdentDefs.newTree(
            newIdentNode("ugen_call_type"),
            nnkBracketExpr.newTree(
                newIdentNode("typedesc"),
                newIdentNode("CallType")
            ),
            newIdentNode("InitCall")
        )
    )

    #Add proc_formal_params to proc definition
    proc_def.add(proc_formal_params)

    #add inline pragma to proc definition
    proc_def.add(
        nnkPragma.newTree(
            newIdentNode("inline")
        ),
        newEmptyNode()
    )
    
    #Add the function body to the proc declaration
    proc_def.add(proc_body)

    #Add proc to result
    final_stmt_list.add(proc_def)

    #Convert the typed statement to an untyped one
    let final_stmt_list_untyped = typedToUntyped(final_stmt_list)

    #error repr final_stmt_list_untyped
    
    return quote do:
        `final_stmt_list_untyped`