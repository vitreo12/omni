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

import macros, strutils, tables, omni_invalid, omni_type_checker, omni_macros_utilities, omni_parser

const omni_valid_struct_generics = [
    "int", "int32", "int64",
    "float", "float32", "float64",
    "signal", "signal32", "signal64",
    "sig", "sig32", "sig64"
]

proc omni_find_data_generics_bottom(statement : NimNode, how_many_datas : var int) : NimNode {.compileTime.} =
    if statement.kind == nnkBracketExpr:
        let statement_ident = statement[0]
        if statement_ident.kind == nnkIdent or statement_ident.kind == nnkSym:
            let statement_ident_str = statement_ident.strVal()
            #Data, keep searching
            if statement_ident_str == "Data" or statement_ident_str == "Data_omni_struct_ptr":
                how_many_datas += 1
                return omni_find_data_generics_bottom(statement[1], how_many_datas)
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
macro omni_declare_struct*(obj_type_def : untyped, ptr_type_def : untyped, alias_type_def : untyped, var_names : untyped, fields_untyped : untyped, fields_typed : varargs[typed]) : untyped =
    var 
        final_stmt_list = nnkStmtList.newTree()          #return statement
        type_section    = nnkTypeSection.newTree()       #the whole type section (both omni_struct and ptr)
        obj_ty          = nnkObjectTy.newTree(
            newEmptyNode(),
            newEmptyNode()
        )

        rec_list        = nnkRecList.newTree()           #the variable declaration section of Phasor_omni_struct

    var
        untyped_counter = 0
        typed_counter   = 0

    var fields_typed_to_signal_generics : seq[NimNode]

    for field_typed in fields_typed:
        var 
            how_many_datas = 0
            field_typed_to_signal_generics = omni_find_data_generics_bottom(field_typed, how_many_datas)

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
    
    #Add the type declaration of Phasor_omni_struct to the type section
    type_section.add(obj_type_def)
    
    #Add the type declaration of Phasor to type section
    type_section.add(ptr_type_def)

    #Add the type declaration of Phasor_omni_struct_ptr
    type_section.add(alias_type_def)

    #Add the whole type section to result
    final_stmt_list.add(type_section)

    #error astgenrepr final_stmt_list
    # error repr final_stmt_list

    return quote do:
        `final_stmt_list`

#Check if a struct field contains generics
proc omni_struct_untyped_or_typed_generics(var_type : NimNode, generics_seq : seq[NimNode]) : bool {.compileTime.} =
    if var_type.kind == nnkBracketExpr:
        let var_type_ident = var_type[0]
        if var_type_ident.kind == nnkIdent:
            let var_type_ident_str = var_type_ident.strVal()
            #Data, keep searching
            if var_type_ident_str == "Data" or var_type_ident_str == "Data_omni_struct_ptr":
                return omni_struct_untyped_or_typed_generics(var_type[1], generics_seq)
            
            #Normal bracket expr like Phasor[T] or Phasor[int]
            else:
                return true
    
    #Bottom of the search
    elif var_type.kind == nnkIdent:
        if (var_type.strVal() in omni_valid_struct_generics) or (var_type in generics_seq):
            return true  

    return false 

proc omni_execute_check_valid_types_macro_and_check_struct_fields_generics(statement : NimNode, var_name : NimNode, ptr_name : NimNode, generics_seq : seq[NimNode], checkValidTypes : NimNode) : void {.compileTime.} =
    let 
        var_name_str = var_name.strVal()
        ptr_name_str = ptr_name.strVal()

    if statement.kind == nnkBracketExpr:
        var already_looped = false

        #Check validity of structs that are not Datas
        if statement[0].strVal() != "Data" and statement[0].strVal() != "Data_omni_struct_ptr":
            already_looped = true
            for index, entry in statement:
                if index == 0:
                    continue
                
                if entry.kind != nnkIdent and entry.kind != nnkSym:
                    error "'struct " & ptr_name_str & "': invalid field '" & var_name_str &  "': it contains invalid type '" & repr(statement) & "'"
                
                let entry_str = entry.strVal()
                if (not (entry_str in omni_valid_struct_generics)) and (not(entry in generics_seq)):
                    error "'struct " & ptr_name_str & "': invalid field '" & var_name_str &  "': it contains invalid type '" & repr(statement) & "'"
                
                omni_execute_check_valid_types_macro_and_check_struct_fields_generics(entry, var_name, ptr_name, generics_seq, checkValidTypes)
                
                if not(entry in generics_seq):
                    checkValidTypes.add(
                        nnkCall.newTree(
                            newIdentNode("omni_check_valid_type_macro"),
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
                omni_execute_check_valid_types_macro_and_check_struct_fields_generics(entry, var_name, ptr_name, generics_seq, checkValidTypes)
                
                if entry.kind == nnkIdent or entry.kind == nnkSym:
                    if not(entry in generics_seq):
                        checkValidTypes.add(
                            nnkCall.newTree(
                                newIdentNode("omni_check_valid_type_macro"),
                                entry,
                                newLit(var_name_str), 
                                newLit(false),
                                newLit(false),
                                newLit(true),
                                newLit(ptr_name_str)
                            )
                        )

    #All other cases
    else:
        if not(statement in generics_seq):
            checkValidTypes.add(
                nnkCall.newTree(
                    newIdentNode("omni_check_valid_type_macro"),
                    statement,
                    newLit(var_name_str), 
                    newLit(false),
                    newLit(false),
                    newLit(true),
                    newLit(ptr_name_str)
                )
            )

macro omni_struct_parse_call*(block_call : typed) : untyped =
    let call = block_call[1][^1]
    error astGenRepr (call[0].getTypeImpl)[0][0]

#Entry point for struct
macro struct*(struct_name : untyped, code_block : untyped) : untyped =
    var 
        obj_type_def    = nnkTypeDef.newTree()           #the Phasor_omni_struct block

        ptr_type_def    = nnkTypeDef.newTree()           #the Phasor = ptr Phasor_omni_struct block
        ptr_ty          = nnkPtrTy.newTree()             #the ptr type expressing ptr Phasor_omni_struct
        
        alias_type_def : NimNode

        generics_seq : seq[NimNode]
        checkValidTypes = nnkStmtList.newTree()        #Check that types fed to struct are correct omni types
    
    var 
        obj_name : NimNode
        ptr_name : NimNode
        alias_name : NimNode

        generics = nnkGenericParams.newTree()          #If generics are present in struct definition

        obj_bracket_expr : NimNode

    var
        var_names      = nnkStmtList.newTree()
        fields_untyped = nnkStmtList.newTree()
        fields_typed   : seq[NimNode]
        var_inits      = nnkStmtList.newTree()

    var struct_name_str : string

    #Using generics
    if struct_name.kind == nnkBracketExpr:
        struct_name_str = struct_name[0].strVal()
        
        obj_name = newIdentNode(struct_name_str & "_omni_struct")  #Phasor_omni_struct
        alias_name = newIdentNode(struct_name_str & "_omni_struct_ptr")
        ptr_name = struct_name[0]                                     #Phasor

        #If struct name doesn't start with capital letter, error out
        if not(ptr_name.strVal[0] in {'A'..'Z'}):
            error("struct '" & $ptr_name & $ "' must start with a capital letter")

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

        #Initialize them to be bracket expressions and add the "Phasor_omni_struct" and "Phasor" names to brackets
        obj_bracket_expr = nnkBracketExpr.newTree(
            obj_name
        )

        for index, child in struct_name:
            if index == 0:
                continue
            else:
                var generic_proc = nnkIdentDefs.newTree()
                    
                #If singular [T]
                if child.len() == 0:
                    ##Also add the name of the generic to the Phasor_omni_struct[T, Y...]
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

        #Add the Phasor_omni_struct[T, Y] to ptr_ty, for object that the pointer points at.
        ptr_ty.add(obj_bracket_expr)

    #No generics, just name of struct
    elif struct_name.kind == nnkIdent:
        struct_name_str = struct_name.strVal()
        
        obj_name = newIdentNode(struct_name_str & "_omni_struct")              #Phasor_omni_struct
        alias_name = newIdentNode(struct_name_str & "_omni_struct_ptr") 
        ptr_name = struct_name                                        #Phasor

        #If struct name doesn't start with capital letter, error out
        if not(ptr_name.strVal[0] in {'A'..'Z'}):
            error("struct '" & $ptr_name & $ "' must start with a capital letter")
        
        #Add name to obj_type_def. Needs to be aliased for proper working!
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

        #Add the Phasor_omni_struct[T, Y] to ptr_ty, for object that the pointer points at.
        ptr_ty.add(obj_name)

        #When not using generics, the sections where the bracket generic expression is used are just the normal name of the type
        obj_bracket_expr = obj_name
    
    else:
        error "struct: Invalid name: '" & repr(struct_name) & "'"

    #Detect invalid struct name
    if struct_name_str in omni_invalid_idents:
        error("struct: Trying to redefine in-built struct '" & struct_name_str & "'")

    #Detect invalid ends with
    for invalid_ends_with in omni_invalid_ends_with:
        if struct_name_str.endsWith(invalid_ends_with):
            error("struct: Name can't end with '" & invalid_ends_with & "': it's reserved for internal use.")

    #Loop over struct's body
    for code_stmt in code_block:
        let code_stmt_kind = code_stmt.kind

        var 
            var_name : NimNode
            var_type : NimNode
            var_init : NimNode

        #NO type defined, default it to float
        if code_stmt_kind == nnkIdent:
            var_name = code_stmt
            var_type = newIdentNode("float")

        #phase float
        elif code_stmt_kind == nnkCommand:
            var_name = code_stmt[0]
            var_type = code_stmt[1]

            if var_name.kind != nnkIdent:
                error "struct " & repr(ptr_name) & ": Invalid field name in '" & repr(code_stmt) & "'"
            
            let var_type_kind = var_type.kind

            #Type can either be an ident, a bracket expr (generics) or a tuple (par)
            if var_type_kind != nnkIdent:
                if var_type_kind != nnkBracketExpr and var_type_kind != nnkPar:
                    error "struct '" & repr(ptr_name) & "': Invalid field type in '" & repr(code_stmt) & "'"

        #phase = 0.0 / phase float = 0.0
        elif code_stmt_kind == nnkAsgn:
            let
                asgn_left  = code_stmt[0]
                asgn_left_kind = asgn_left.kind
                asgn_right = code_stmt[1]
                asgn_right_kind = asgn_right.kind

            #TODO: add support for other calling syntaxes (Data 100, Data.new(), Data.new, new Data, etc...) 
            #This also has to be reflected later when using var_init in omni_struct_create_init_proc_and_template
            if asgn_right_kind == nnkCall or asgn_right_kind == nnkFloatLit or asgn_right_kind == nnkIntLit:
                var_init = asgn_right
                
                #phase = 0
                if asgn_left_kind == nnkIdent:
                    var_name = asgn_left
                    if asgn_right_kind != nnkFloatLit and asgn_right_kind != nnkIntLit:
                        var_type = var_init[0] #Naively extract type from constructor call 'Data(100)'
                    else:
                        var_type = newIdentNode("float")
                
                #phase float = 0
                elif asgn_left_kind == nnkCommand:
                    var_name = asgn_left[0]
                    var_type = asgn_left[1]

                else:
                    error "struct '" & repr(ptr_name) & "': Invalid field assignment: '" & repr(asgn_left) & "'"
            else:
                error "struct '" & repr(ptr_name) & "': Invalid field initialization: '" & repr(asgn_right) & "'"
        else:
            error "struct '" & repr(ptr_name) & "': Invalid field '" & repr(code_stmt) & "'"

        var var_type_untyped_or_typed = false

        var_type_untyped_or_typed = omni_struct_untyped_or_typed_generics(var_type, generics_seq)

        omni_execute_check_valid_types_macro_and_check_struct_fields_generics(var_type, var_name, ptr_name, generics_seq, checkValidTypes)

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

        var_inits.add(var_init)

    #Add the ptr_ty inners to ptr_type_def, so that it is completed when sent to omni_declare_struct
    ptr_type_def.add(ptr_ty)

    #Build the Phasor_omni_struct_ptr out of the ptr
    alias_type_def = ptr_type_def.copy()
    alias_type_def[0][1] = alias_name
    alias_type_def[^1] = alias_type_def.last()[0]

    #Generics
    if alias_type_def.last().kind == nnkBracketExpr:
        alias_type_def[^1][0] = ptr_name
    else:
        alias_type_def[^1] = ptr_name

    #error repr alias_type_def

    #The init_struct macro, which will declare the "proc omni_struct_new ..." and the "template new ..."
    let omni_struct_create_init_proc_and_template = nnkCall.newTree(
        newIdentNode("omni_struct_create_init_proc_and_template"),
        ptr_name,
        var_inits
    )

    let omni_find_structs_and_datas = nnkCall.newTree(
        newIdentNode("omni_find_structs_and_datas"),
        ptr_name
    )

    var omni_declare_struct = nnkCall.newTree(
        newIdentNode("omni_declare_struct"),
        obj_type_def,
        ptr_type_def,
        alias_type_def,
        var_names,
        fields_untyped
    )

    for field_typed in fields_typed:
        omni_declare_struct.add(field_typed)

    # error astGenRepr checkValidTypes
    
    let test = quote do:
        block: 
            let 
                bufsize            {.inject.} : int            = 0
                samplerate         {.inject.} : float          = 0.0
                buffer_interface   {.inject.} : pointer        = nil
                omni_auto_mem      {.inject.} : Omni_AutoMem   = nil
            
            var omni_call_type     {.inject, noinit.} : typedesc[Omni_CallType]

            newSomething()

    return quote do:
        # omni_struct_parse_call(`test`)

        `checkValidTypes`
        `omni_declare_struct`
        `omni_struct_create_init_proc_and_template`
        `omni_find_structs_and_datas`

#convert a type to standard G1 generics
proc omni_convert_generic_type(field_type : NimNode, generics_mapping : OrderedTable[string, NimNode]) : void {.compileTime.} =
    for index, entry in field_type:
        let entry_kind = entry.kind
        if entry_kind == nnkIdent or entry_kind == nnkSym:
              let 
                entry_str_val = entry.strVal()
                generic_mapping = generics_mapping.getOrDefault(entry_str_val)
              if generic_mapping != nil:
                  field_type[index] = generic_mapping
        omni_convert_generic_type(entry, generics_mapping)

#Declare the "proc omni_struct_new ..." and the "template new ...", doing all sorts of type checks
macro omni_struct_create_init_proc_and_template*(ptr_struct_name : typed, var_inits : untyped) : untyped =
    if ptr_struct_name.kind != nnkSym:
        error "struct: Invalid struct ptr symbol!"

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

        proc_def             = nnkProcDef.newTree()      #the omni_struct_new* proc
        proc_formal_params   = nnkFormalParams.newTree() #the whole [T](args..) : returntype 
        proc_body            = nnkStmtList.newTree()     #body of the proc

    #The name of the function with the asterisk, in case of supporting modules in the future
    #proc Phasor_omni_struct_new
    proc_def.add(
        nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode(ptr_name & "_omni_struct_new")
        ),
        newEmptyNode(),
        newEmptyNode()
    )

    #Generics
    if obj_struct_name_kind == nnkBracketExpr:
        let obj_struct_name_ident = obj_struct_name[0]
        obj_struct_type = (obj_struct_name_ident).getTypeImpl()

        #Initialize them to be bracket expressions and add the "Phasor_omni_struct" and "Phasor" names to brackets
        obj_bracket_expr = nnkBracketExpr.newTree(obj_struct_name[0])
        ptr_bracket_expr = nnkBracketExpr.newTree(ptr_struct_name)

        #Retrieve generics
        for index, generic_ident in obj_struct_name.pairs():
            if index == 0:
                continue

            let new_G_generic_ident = newIdentNode("G" & $index)

            ##Also add the name of the generic to the Phasor_omni_struct[T, Y...]
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

    #This is the _omni_struct_ptr. Don't put the generics in! They will fail some constructors otherwise
    var omni_struct_ptr_arg =  newIdentNode(ptr_struct_name.strVal() & "_omni_struct_ptr")

    #Add the when... check for omni_call_type to see if user is trying to allocate memory in perform!
    proc_body.add(
        nnkWhenStmt.newTree(
            nnkElifBranch.newTree(
                nnkInfix.newTree(
                    newIdentNode("is"),
                    newIdentNode("omni_call_type"),
                    newIdentNode("Omni_PerformCall")
                ),
                nnkStmtList.newTree(
                    nnkPragma.newTree(
                        nnkExprColonExpr.newTree(
                            newIdentNode("fatal"),
                            newLit("struct '" & ptr_name & "': attempting to allocate memory in the 'perform' or 'sample' blocks.")
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
                                    newLit("struct '" & ptr_name & "': " & $generic_ident.strVal() & " must be some number type.")
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
                    newIdentNode("omni_alloc0"),
                        nnkCall.newTree(
                            newIdentNode("sizeof"),
                            obj_bracket_expr
                        )              
                    )
                )
            )
        )

    #Add "omni_auto_mem_register_child(omni_auto_mem, result)"
    proc_body.add(
        nnkCall.newTree(
            newIdentNode("omni_auto_mem_register_child"),
            newIdentNode("omni_auto_mem"),
            newIdentNode("result")
        )
    )

    let struct_fields = obj_struct_type[2]

    for index, field in struct_fields:
        assert field.len == 3
        assert var_inits.len == struct_fields.len

        var 
            field_name = field[0]
            field_type = field[1]
            field_init = var_inits[index]
            field_type_kind = field_type.kind

        var field_type_without_generics = field_type
        
        if field_type_kind == nnkBracketExpr:
            field_type_without_generics = field_type[0]
        
        #Skip tuples
        elif field_type_kind == nnkTupleConstr:
            continue

        let field_type_without_generics_str = field_type_without_generics.strVal()
    
        let 
            field_is_struct  = field_type_without_generics.omni_is_struct()
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
        
        #If field is struct, pass the explicit or default constructor as a string
        if field_is_struct:
            #If no init provided, use default constructor of the type
            if field_init == nil:
                field_init = nnkCall.newTree(field_type)
            
            #Convert Something[T](10) to Something[G1](10)
            omni_convert_generic_type(field_init, generics_mapping)

            #Have a string as arg default value: it's checked later!
            arg_field_value = newStrLitNode("")

        #Else pass the value through
        else:
            if field_init == nil:
                arg_field_value = newIntLitNode(0)    
            else:
                arg_field_value = field_init

        # echo astGenRepr arg_field_value

        #Add to arg list for omni_struct_new proc
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
                nnkStmtList.newTree(
                    nnkWhenStmt.newTree(
                        nnkElifBranch.newTree(
                            nnkInfix.newTree(
                                newIdentNode("is"),
                                field_name,
                                #If arg is string (""),
                                newIdentNode("string")
                            ),
                            nnkLetSection.newTree(
                                nnkIdentDefs.newTree(
                                    field_name,
                                    newEmptyNode(),
                                    #Build the constructor call using the parser function!
                                    omni_find_struct_constructor_call(
                                        field_init
                                    )
                                )
                            )
                        )
                    ),
                  
                    nnkAsgn.newTree(
                        nnkDotExpr.newTree(
                            newIdentNode("result"),
                            field_name
                        ),
                        field_name
                    )
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
    # omni_struct_new PROC  #
    # ===================== #

    #Add generics
    if generics_ident_defs.len > 0:
        for generic_ident_defs in generics_ident_defs:
            proc_formal_params.add(generic_ident_defs)

    #Add samplerate and bufsize
    proc_formal_params.add(
        nnkIdentDefs.newTree(
            newIdentNode("samplerate"),
            newIdentNode("float"),
            newEmptyNode()
        ),
        nnkIdentDefs.newTree(
            newIdentNode("bufsize"),
            newIdentNode("int"),
            newEmptyNode()
        )
    )

    #Add omni_struct_type
    proc_formal_params.add(
        nnkIdentDefs.newTree(
            newIdentNode("omni_struct_type"),
            nnkBracketExpr.newTree(
                newIdentNode("typedesc"),
                omni_struct_ptr_arg
            ),
            newEmptyNode()
        )   
    )
    
    #Add omni_auto_mem : Omni_AutoMem argument
    proc_formal_params.add(
        nnkIdentDefs.newTree(
            newIdentNode("omni_auto_mem"),
            newIdentNode("Omni_AutoMem"),
            newEmptyNode()
        )
    )

    #Add omni_call_type as last argument
    proc_formal_params.add(
        nnkIdentDefs.newTree(
            newIdentNode("omni_call_type"),
            nnkBracketExpr.newTree(
                newIdentNode("typedesc"),
                newIdentNode("Omni_CallType")
            ),
            newIdentNode("Omni_InitCall")
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

    echo repr final_stmt_list

    #Convert the typed statement to an untyped one
    let final_stmt_list_untyped = typed_to_untyped(final_stmt_list)

    # error repr final_stmt_list_untyped
    
    return final_stmt_list_untyped
