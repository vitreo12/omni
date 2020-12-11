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

import macros, os, strutils, tables, omni_invalid, omni_macros_utilities

#type
#    ImportMe1 = ImportMe_omni_module.ImportMe_omni_struct_ptr
#type
#    ImportMe1_omni_struct_ptr = ImportMe1
#
#proc ImportMe1_new_omni_struct(omni_struct_type : typedesc[ImportMe1_omni_struct_ptr], ...) : ImportMe1 {.inline.} =
#    return ImportMe_omni_module.ImportMe_new_omni_struct(....)

proc omni_generate_new_module_bindings_for_struct(module_name : NimNode, struct_typed : NimNode, struct_typed_constructor : NimNode, struct_new_name : NimNode) : NimNode {.compileTime.} =
    result = nnkStmtList.newTree()

    var 
        struct_typed_inner : NimNode
        struct_typed_generic_params : NimNode
        stuct_typed_rec_list : NimNode
        struct_typed_name_str : string

    #Generics
    if struct_typed[2].kind == nnkBracketExpr:
        let old_struct_typed = struct_typed[2][0]
        struct_typed_name_str = old_struct_typed.strVal()
        struct_typed_generic_params = struct_typed[1]
        struct_typed_inner = old_struct_typed.getType()[1][0].getTypeImpl()
    
    #Normal
    else:
        let old_struct_typed = struct_typed[2]
        struct_typed_name_str = old_struct_typed.strVal()
        struct_typed_generic_params = newEmptyNode()
        struct_typed_inner = old_struct_typed.getType()[1].getTypeImpl()
        
    stuct_typed_rec_list = struct_typed_inner[2]

    let 
        struct_new_name_str = struct_new_name.strVal()
        struct_new_name_ident = newIdentNode(struct_new_name_str)
        struct_new_name_export_ident = newIdentNode(struct_new_name_str & "_omni_struct_ptr")
        struct_new_name_omni_struct_new_ident = newIdentNode(struct_new_name_str & "_omni_struct_new")
        old_struct_name_export_ident = newIdentNode(struct_typed_name_str & "_omni_struct_ptr")

    #put generics again if needed
    var 
        generics_ident_defs = newEmptyNode()
        old_struct_name_export : NimNode

    let 
        stuct_typed_constuctor_impl = struct_typed_constructor.getImpl()

        #Untyped translation, to retrieve formal params from (and modify them)
        stuct_untyped_constuctor_impl = typed_to_untyped(stuct_typed_constuctor_impl)[0]
        struct_untyped_formal_params = stuct_untyped_constuctor_impl[3]

    var 
        #can copy from old impl, they are typed symbols anyway! Only thing to change is the first arg, omni_struct_type
        new_struct_formal_params = struct_untyped_formal_params

        old_struct_constructor = nnkDotExpr.newTree(
            module_name,
            newIdentNode(struct_typed_name_str & "_omni_struct_new")
        )

    #call to old struct
    old_struct_name_export = nnkDotExpr.newTree(
        module_name,
        old_struct_name_export_ident
    )

    #Add generics to type descriptions!
    if struct_typed_generic_params.len > 0:
        generics_ident_defs = nnkGenericParams.newTree()

        #Add old generics to old name export
        old_struct_name_export = nnkBracketExpr.newTree(
            old_struct_name_export
        )

        for i, generic_param in struct_typed_generic_params: 
            #Must be untyped here!
            let generic_param_untyped = newIdentNode(generic_param.strVal())

            old_struct_name_export.add(generic_param_untyped)

            #No specification for type declarations
            let new_generic_ident_def = nnkIdentDefs.newTree(
                generic_param_untyped,
                newEmptyNode(),
                newEmptyNode()
            )

            generics_ident_defs.add(new_generic_ident_def)

    #error astGenRepr stuct_typed_constuctor_impl

    #Final return stmt
    var 
        new_struct_call = nnkCall.newTree(
            old_struct_constructor,
        )
        
        return_stmt = nnkStmtList.newTree(
            nnkReturnStmt.newTree(
                new_struct_call
            )
        )

    #Add args from the struct's rec list
    for ident_def in stuct_typed_rec_list:
        let untyped_ident_def = newIdentNode(ident_def[0].strVal())
        new_struct_call.add(untyped_ident_def)

    #Change return type to be the new declared struct
    var return_type_formal_params = new_struct_formal_params[0]

    #Generics (G1, G2, ...). Change return name and add generics (G1, G2, etc...) to call.
    if return_type_formal_params.kind == nnkBracketExpr:
        new_struct_formal_params[0][0] = struct_new_name_ident
        for i, generic_param in return_type_formal_params:
            if i == 0: continue #skip name
            new_struct_call.add(generic_param)
    else:
        new_struct_formal_params[0] = struct_new_name_ident

    #Change name in omni_struct_type argument (third last)
    new_struct_formal_params[^3][1][1] = struct_new_name_export_ident

    #Add omni_struct_type, omni_auto_mem and omni_call_type etc...
    new_struct_call.add(
        newIdentNode("omni_struct_type"),
        newIdentNode("omni_auto_mem"),
        newIdentNode("omni_call_type"),
    )

    let new_struct = nnkTypeSection.newTree(
        nnkTypeDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                struct_new_name_ident
            ),
            generics_ident_defs,
            old_struct_name_export
        )
    )

    let new_omni_struct_ptr = nnkTypeSection.newTree(
        nnkTypeDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                struct_new_name_export_ident
            ),
            generics_ident_defs,
            struct_new_name_ident
        )
    )

    #Copy the old func's body? Not really needed
    #return_stmt = stuct_typed_constuctor_impl[^1]

    var new_omni_struct_new = nnkProcDef.newTree(
        nnkPostfix.newTree(
            newIdentNode("*"),
            struct_new_name_omni_struct_new_ident
        ),
        newEmptyNode(),
        newEmptyNode(),
        new_struct_formal_params,
        nnkPragma.newTree(
            newIdentNode("inline")
        ),
        newEmptyNode(),
        return_stmt
    )

    result.add(
        new_struct,
        new_omni_struct_ptr,
        new_omni_struct_new
    )

    #error astGenRepr new_struct
    #error repr result


proc omni_generate_new_modue_bindings_for_def(module_name : NimNode, def_call : NimNode, def_new_name : NimNode, def_combinations : var OrderedTable[string, NimNode]) : NimNode {.compileTime.} =
    result = nnkStmtList.newTree()

    let 
        def_call_proc_def_typed = def_call.getImpl()
        generic_params = def_call_proc_def_typed[2]
        formal_params = def_call_proc_def_typed[3]

    var
        new_template_generic_params = nnkGenericParams.newTree()
        
        new_template_formal_params = nnkFormalParams.newTree(
            newIdentNode("untyped"),
        )

        new_template_call = nnkCall.newTree(
            def_call #using the symbol, no need to do Module.Function, right?
        )

        new_template = nnkTemplateDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode(def_new_name.strVal())
            ),
            newEmptyNode()
        )   

    for generic_param in generic_params:
        #ignore autos and omni_call_type:type in generics!
        if not (generic_param.strVal().endsWith(":type")):
            new_template_generic_params.add(
                nnkIdentDefs.newTree(
                    newIdentNode(generic_param.strVal()),
                    newIdentNode("SomeNumber"), #generics are always SomeNumber (for now)
                    newEmptyNode()
                )
            )

    #If generic params
    if generic_params.len > 1: # 1 because there's always omni_call_type:type
        new_template.add(new_template_generic_params)
    
    #no generics
    else:
        new_template.add(newEmptyNode())

    for i, formal_param in formal_params:
        #skip return type (first formal param)
        if i != 0: 
            let 
                arg_name = formal_param[0]
                arg_name_str = arg_name.strVal()
                arg_type = formal_param[1]

            #echo astGenRepr arg_type.getTypeImpl()

            var arg_type_str : string
            if arg_type.kind == nnkIdent or arg_type.kind == nnkSym:
                arg_type_str = arg_type.strVal()
            else:
                arg_type_str = arg_type[0].strVal()
            
            #ImportMe -> ImportMe_omni_module.ImportMe_omni_struct_ptr
            #[ let inner_type = arg_type.getTypeImpl()
            if inner_type.kind == nnkPtrTy:
                if inner_type[0].strVal().endsWith("_omni_struct"):
                    #is this needed? Os is arg_type enough since it's a symbol?
                    let new_arg_type = parseStmt(module_name.strVal() & "." & arg_type_str & "_omni_struct_ptr")[0]
            
                    #error astGenRepr new_arg_type  ]#

            #Skip samplerate. bufsize, omni_auto_mem, omni_call_type
            if arg_name_str != "samplerate" and arg_name_str != "bufsize" and arg_name_str != "omni_auto_mem" and arg_name_str != "omni_call_type":    
                new_template_formal_params.add(
                    nnkIdentDefs.newTree(
                        arg_name,
                        arg_type, #pass the symbols, they already have type infos!!
                        newEmptyNode()
                    )
                )
        
            new_template_call.add(arg_name)

    new_template.add(
        new_template_formal_params,
        newEmptyNode(),
        newEmptyNode(),
        nnkStmtList.newTree(
            new_template_call
        )
    )
    
    #This will override entries, which is perfect! I need last representation of each duplicate
    #So that imports of imports are overwritten. (Basically, if a func is defined in two files, and one is imported in the other, only the last one is considered!)
    #This is only needed to create new omni_def_exports, as templates override each other already 
    let formal_params_repr = repr(new_template_formal_params)
    def_combinations[formal_params_repr] = def_call

    result.add(new_template)

proc omni_generate_new_module_bindings_for_struct_or_def_inner(module_name : NimNode, struct_or_def_typed : NimNode, struct_constructor_typed : NimNode, struct_or_def_new_name : NimNode, def_combinations : var OrderedTable[string, NimNode]) : NimNode {.compileTime.} =
    result = nnkStmtList.newTree()

    let struct_or_def_impl = struct_or_def_typed.getImpl()

    #Struct
    if struct_or_def_impl.kind == nnkTypeDef:
        let new_struct = omni_generate_new_module_bindings_for_struct(module_name, struct_or_def_impl, struct_constructor_typed, struct_or_def_new_name)
        result.add(new_struct)
    
    #Def
    elif struct_or_def_impl.kind == nnkProcDef:
        let actual_def_call = struct_or_def_impl[^1]

        #multiple ones with same name
        if actual_def_call.kind == nnkOpenSymChoice:
            for def_call in actual_def_call:
                let new_template = omni_generate_new_modue_bindings_for_def(module_name, def_call, struct_or_def_new_name, def_combinations)
                result.add(new_template)
        
        if actual_def_call.kind == nnkSym:
            let new_template = omni_generate_new_modue_bindings_for_def(module_name, actual_def_call, struct_or_def_new_name, def_combinations)
            result.add(new_template)

        #error repr result
    
proc omni_generate_new_omni_def_exports(def_combinations : OrderedTable[string, NimNode], def_new_name : NimNode) : NimNode {.compileTime.} =
    result = nnkStmtList.newTree()
    for key, value in def_combinations:
        let 
            def_call = value

            def_new_name_str = def_new_name.strVal()

        #omni_def_dummy
        let 
            omni_def_dummy_name = newIdentNode(def_new_name_str & "_omni_def_dummy")
            omni_def_export = newIdentNode(def_new_name_str & "_omni_def_export")
            
            omni_def_dummy = nnkWhenStmt.newTree(
                nnkElifBranch.newTree(
                    nnkPrefix.newTree(
                        newIdentNode("not"),
                        nnkCall.newTree(
                            newIdentNode("declared"),
                            omni_def_dummy_name
                        )
                    ),
                    nnkStmtList.newTree(
                        nnkProcDef.newTree(
                            nnkPostfix.newTree(
                                newIdentNode("*"),
                                omni_def_dummy_name
                            ),
                            newEmptyNode(),
                            newEmptyNode(),
                            nnkFormalParams.newTree(
                                newEmptyNode()
                            ),
                            newEmptyNode(),
                            newEmptyNode(),
                            nnkStmtList.newTree(
                                nnkDiscardStmt.newTree(
                                    newEmptyNode()
                                )
                            )
                        ),
                        nnkProcDef.newTree(
                            nnkPostfix.newTree(
                                newIdentNode("*"),
                                omni_def_export
                            ),
                            newEmptyNode(),
                            newEmptyNode(),
                            nnkFormalParams.newTree(
                                newEmptyNode()
                            ),
                            newEmptyNode(),
                            newEmptyNode(),
                            nnkStmtList.newTree(
                                nnkDiscardStmt.newTree(
                                    newEmptyNode()
                                )
                            )
                        ),
                    )
                )
            )

        #actual omni_def_export
        var 
            def_call_typed = def_call.getImpl() #typed
            def_call_typed_formal_params = def_call_typed[3] #save formal params! they are typed and carry all type infos
        
        #Remove the actual function body, it's unneeded
        #and it creates problems too with parsing of some return statements, due to the parsed_untyped_loop being triggered with typed_to_untyped
        def_call_typed[^1] = nnkDiscardStmt.newTree(
            newEmptyNode()
        )

        #This is only needed to change name to omni_def_export, tbh... Find a cleaner solution
        var new_omni_def_export = typed_to_untyped(def_call_typed)[0] #typed to untyped

        #Change name
        new_omni_def_export[0] = nnkPostfix.newTree(
            newIdentNode("*"),
            omni_def_export
        )

        #If it has generics, need to be SomeNumber! Or type info won't work
        var generic_params = new_omni_def_export[2]
        for generic_param in generic_params:
            generic_param[1] = newIdentNode("SomeNumber")

        #Use typed formal params (so all type information on arguments and return types is preserverd)
        new_omni_def_export[3] = def_call_typed_formal_params

        #Use the actual def_call in order to maintain all type information and module belonging!
        #This must be put here (and not before typed_to_untyped) in order for the nnkSym to be maintained after the typed_to_untyped
        new_omni_def_export[^1] = def_call 

        result.add(
            omni_def_dummy,
            new_omni_def_export
        )

    #error repr result

macro omni_generate_new_module_bindings_for_struct_or_def*(module_name : untyped, struct_or_def_typed : typed, struct_constructor_typed : typed = nil, struct_or_def_new_name : untyped) : untyped =    
    var def_combinations : OrderedTable[string, NimNode]
    result = nnkStmtList.newTree()

    #error astGenRepr struct_or_def_typed

    if struct_or_def_typed.kind == nnkSym:
        let new_structs_or_def_templates = omni_generate_new_module_bindings_for_struct_or_def_inner(module_name, struct_or_def_typed, struct_constructor_typed, struct_or_def_new_name, def_combinations)
        result.add(new_structs_or_def_templates)
        
    elif struct_or_def_typed.kind == nnkClosedSymChoice:
        result = nnkStmtList.newTree()

        #error astGenRepr struct_or_def_typed
        
        for struct_or_def_choice in struct_or_def_typed:
            let new_structs_or_def_templates = omni_generate_new_module_bindings_for_struct_or_def_inner(module_name, struct_or_def_choice, struct_constructor_typed, struct_or_def_new_name, def_combinations)
            result.add(new_structs_or_def_templates)

    #Only for defs
    let new_omni_def_exports = omni_generate_new_omni_def_exports(def_combinations, struct_or_def_new_name)
    result.add(new_omni_def_exports)

    #error repr result
    
#use with normal import / export
proc omni_use_inner(paths : NimNode) : NimNode {.compileTime.} =
    result = nnkStmtList.newTree()

    for path in paths:
        var 
            real_path = path
            import_name_without_extension : string

        #"ImportMe.omni"
        if path.kind == nnkStrLit:
            import_name_without_extension = path.strVal().splitFile().name

        #ImportMe
        elif path.kind == nnkIdent:
            import_name_without_extension = path.strVal()
            
            #what about .oi? a solution would be: https://forum.nim-lang.org/t/3752#43859.
            #Basically, testing using when (compiles do: import ImportMe)
            let import_name_omni = import_name_without_extension & ".omni"
            real_path = newLit(import_name_omni)

            #Check if .omni or .oi exist, and use that... doesnt work now cause it will not find the current used omni file
            #[ let 
                import_name_omni = import_name_without_extension & ".omni"
                import_name_oi = import_name_without_extension & ".oi"

            var omni_exists = false

            if fileExists(import_name_omni):
                omni_exists = true
                real_path = newIdentNode(import_name_omni)
            
            if fileExists(import_name_oi):
                if omni_exists:
                    error "Both '" & import_name_oi & "' and '" & import_name_omni & "' exist. Which one to use?"
                
                real_path = newIdentNode(import_name_oi)
            
            else:
                error "Can't find either '" & import_name_oi & "' or '" & import_name_omni & "'" ]#

        #../../ImportMe
        elif path.kind == nnkPrefix or path.kind == nnkInfix:
            let 
                path_last = path.last()
                path_last_kind = path_last.kind

            if path_last_kind != nnkIdent and path_last_kind != nnkStrLit:
                error "use: Invalid path syntax: " & repr(path)
            
            #strLit already has Something/"Module.omni" figured out
            if path_last_kind == nnkIdent:
                import_name_without_extension = path_last.strVal()

                #what about .oi?
                let import_name_omni = import_name_without_extension & ".omni" 
                real_path[^1] = newLit(import_name_omni)
            
        else:
            error "use: Invalid path syntax: " & repr(path)

        let omni_module = newIdentNode(import_name_without_extension & "_omni_module")

        result.add(
            nnkImportStmt.newTree(
                nnkInfix.newTree(
                    newIdentNode("as"),
                    real_path,
                    omni_module
                )
            ),
            
            nnkExportStmt.newTree(
                omni_module
            )
        )

#use Path:
    #Something as Something1 
    #someFunc as someFunc1
macro use*(path : untyped, stmt_list : untyped) : untyped =
    result = nnkStmtList.newTree()
        
    var 
        real_path = path
        import_name_without_extension : string

        import_stmt = nnkImportExceptStmt.newTree()
        export_stmt = nnkExportExceptStmt.newTree()

    #"ImportMe.omni"
    if path.kind == nnkStrLit:
        import_name_without_extension = path.strVal().splitFile().name

    #ImportMe
    elif path.kind == nnkIdent:
        import_name_without_extension = path.strVal()
        
        #what about .oi?
        let import_name_omni = import_name_without_extension & ".omni"
        real_path = newLit(import_name_omni)

        #Check if .omni or .oi exist, and use that... doesnt work now cause it will not find the current used omni file
        #[ let 
            import_name_omni = import_name_without_extension & ".omni"
            import_name_oi = import_name_without_extension & ".oi"

        var omni_exists = false

        if fileExists(import_name_omni):
            omni_exists = true
            real_path = newIdentNode(import_name_omni)
        
        if fileExists(import_name_oi):
            if omni_exists:
                error "Both '" & import_name_oi & "' and '" & import_name_omni & "' exist. Which one to use?"
            
            real_path = newIdentNode(import_name_oi)
        
        else:
            error "Can't find either '" & import_name_oi & "' or '" & import_name_omni & "'" ]#
    
    #../../ImportMe
    elif path.kind == nnkPrefix or path.kind == nnkInfix:
        let 
            path_last = path.last()
            path_last_kind = path_last.kind

        if path_last_kind != nnkIdent and path_last_kind != nnkStrLit:
            error "use: Invalid path syntax: " & repr(path)
            
        #strLit already has Something/"Module.omni" figured out
        if path_last_kind == nnkIdent:
            import_name_without_extension = path_last.strVal()

            #what about .oi?
            let import_name_omni = import_name_without_extension & ".omni" 
            real_path[^1] = newLit(import_name_omni)
    else:
        error "use: Invalid path syntax: " & repr(path)

    let import_name_omni_module = newIdentNode(import_name_without_extension & "_omni_module")

    #Add import
    import_stmt.add(
        nnkInfix.newTree(
            newIdentNode("as"),
            real_path,
            import_name_omni_module
        )
    )

    #Add export
    export_stmt.add(
        import_name_omni_module
    )

    #Need to be before all the generate_new_module_bindings_for_struct_or_def_calls
    result.add(
        import_stmt,
        export_stmt
    )
    
    #Add the excepts and add entries to use_build_structs_and_defs_call
    #for type checking 
    for statement in stmt_list:
        if statement.kind == nnkInfix:
            let 
                infix_ident = statement[0]
                infix_ident_str = infix_ident.strVal()
            
            if infix_ident_str == "as":
                let 
                    infix_first_val = statement[1]
                    infix_second_val = statement[2]

                var generate_new_module_bindings_for_struct_or_def_call = nnkCall.newTree(
                    newIdentNode("omni_generate_new_module_bindings_for_struct_or_def"),
                    import_name_omni_module,
                )

                #Add excepts: first entry of infix
                if infix_first_val.kind == nnkIdent:
                    let 
                        infix_first_val_str = infix_first_val.strVal()
                        infix_first_val_omni_struct_ptr = newIdentNode(infix_first_val_str & "_omni_struct_ptr")
                        infix_first_val_omni_struct_new = newIdentNode(infix_first_val_str & "_omni_struct_new")
                    
                    import_stmt.add(infix_first_val)
                    import_stmt.add(infix_first_val_omni_struct_ptr)
                    export_stmt.add(infix_first_val)
                    export_stmt.add(infix_first_val_omni_struct_ptr)

                    let 
                        struct_dot_expr = nnkDotExpr.newTree(
                            import_name_omni_module,
                            infix_first_val_omni_struct_ptr
                        )

                        struct_constructor_dot_expr = nnkDotExpr.newTree(
                            import_name_omni_module,
                            infix_first_val_omni_struct_new
                        )

                        def_dot_expr = nnkDotExpr.newTree(
                            import_name_omni_module,
                            newIdentNode(infix_first_val.strVal() & "_omni_def_export")
                        )

                    var 
                        when_statement_struct_typed = nnkWhenStmt.newTree(
                            nnkElifBranch.newTree(
                                nnkCall.newTree(
                                    newIdentNode("declared"),
                                    struct_dot_expr
                                ),
                                struct_dot_expr
                            ),
                            nnkElifBranch.newTree(
                                nnkCall.newTree(
                                    newIdentNode("declared"),
                                    def_dot_expr
                                ),
                                def_dot_expr
                            ),
                            nnkElse.newTree(
                                nnkPragma.newTree(
                                    nnkExprColonExpr.newTree(
                                        newIdentNode("fatal"),
                                        newLit("use: Undefined identifier '" & infix_first_val.strVal() & "' in '" & repr(statement) & "'")
                                    )
                                )
                            )
                        )

                        when_statement_struct_constructor_typed = nnkWhenStmt.newTree(
                            nnkElifBranch.newTree(
                                nnkCall.newTree(
                                    newIdentNode("declared"),
                                    struct_constructor_dot_expr
                                ),
                                struct_constructor_dot_expr
                            ),
                            nnkElifBranch.newTree(
                                nnkCall.newTree(
                                    newIdentNode("declared"),
                                    def_dot_expr
                                ),
                                newNilLit()
                            ),
                            nnkElse.newTree(
                                nnkPragma.newTree(
                                    nnkExprColonExpr.newTree(
                                        newIdentNode("fatal"),
                                        newLit("use: Undefined constructor '" & infix_first_val_omni_struct_new.strVal() & "' in '" & repr(statement) & "'")
                                    )
                                )
                            )
                        )

                    #When statement: if it's a struct, gonna pass that. Otherwise, gonna pass the def if it's defined
                    generate_new_module_bindings_for_struct_or_def_call.add(
                        when_statement_struct_typed,
                        when_statement_struct_constructor_typed
                    )

                #elif dot expr
                elif infix_first_val.kind == nnkDotExpr:
                    error "use: Import with submodules is not yet implemented: '" & repr(statement) & "'"
                
                else:
                    error "use: Invalid first infix value '" & repr(infix_first_val) & "' in '" & repr(statement) & "'"

                #Add the structs / defs to check: second entry of infix
                if infix_second_val.kind == nnkIdent:
                    let infix_second_val_str = infix_second_val.strVal()
                    
                    var invalid_ends_with_bool = false

                    for invalid_ends_with in omni_invalid_ends_with:
                        if infix_second_val_str.endsWith(invalid_ends_with):
                            invalid_ends_with_bool = true

                    if infix_second_val_str in omni_invalid_idents or invalid_ends_with_bool:
                        error "use: Invalid second infix value '" & infix_second_val_str & "' in '" & repr(statement) & "'. It's an in-built identifier." 

                    generate_new_module_bindings_for_struct_or_def_call.add(
                        infix_second_val
                    )

                    result.add(
                        generate_new_module_bindings_for_struct_or_def_call
                    )

                else:
                    error "use: Invalid second infix value in '" & repr(statement) & "'"
            else:
                #Don't print error for / and \ ... These are used for paths when only 2 are provided (the case of export_stmt.len == 1)
                if infix_ident_str != "/" and infix_ident_str != "\\":
                    error "use: Invalid infix: '" & repr(infix_ident) & "' in '" & repr(statement) & "'"

    #This means it was a use Path1, Path2 (which would still be treated as use with two untyped)
    if export_stmt.len == 1:
        let paths = nnkStmtList.newTree(
            path,
            stmt_list
        )

        result = omni_use_inner(paths)

#use Path
#OR
#use Path1, Path2, Path3
macro use*(paths : varargs[untyped]) : untyped =
    result = omni_use_inner(paths)

#Aliases
macro require*(path : untyped, stmt_list : untyped) : untyped =
    return quote do:
        use(`path`, `stmt_list`)

macro require*(paths : varargs[untyped]) : untyped =
    return quote do:
        use(`paths`)