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

import macros, os, strutils, tables, omni_macros_utilities

#type
#    ImportMe1 = ImportMe_module_inner.ImportMe_struct_export
#type
#    ImportMe1_struct_export = ImportMe1
#
#proc ImportMe1_new_struct_inner(obj_type : typedesc[ImportMe1_struct_export], ...) : ImportMe1 {.inline.} =
#    return ImportMe_module_inner.ImportMe_new_struct_inner(....)

proc generate_new_module_bindings_for_struct(module_name : NimNode, struct_typed : NimNode, struct_typed_constructor : NimNode, struct_new_name : NimNode) : NimNode {.compileTime.} =
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
        struct_new_name_export_ident = newIdentNode(struct_new_name_str & "_struct_export")
        struct_new_name_struct_new_inner_ident = newIdentNode(struct_new_name_str & "_struct_new_inner")
        old_struct_name_export_ident = newIdentNode(struct_typed_name_str & "_struct_export")

    #put generics again if needed
    var 
        generics_ident_defs = newEmptyNode()
        old_struct_name_export : NimNode

    let 
        stuct_typed_constuctor_impl = struct_typed_constructor.getImpl()

        #Untyped translation, to retrieve formal params from (and modify them)
        stuct_untyped_constuctor_impl = typedToUntyped(stuct_typed_constuctor_impl)[0]
        struct_untyped_formal_params = stuct_untyped_constuctor_impl[3]

    var 
        #can copy from old impl, they are typed symbols anyway! Only thing to change is the first arg, obj_type
        new_struct_formal_params = struct_untyped_formal_params

        old_struct_constructor = nnkDotExpr.newTree(
            module_name,
            newIdentNode(struct_typed_name_str & "_struct_new_inner")
        )

    #Add generics to type descriptions!
    if struct_typed_generic_params.len > 0:
        generics_ident_defs = nnkGenericParams.newTree()

        for i, generic_param in struct_typed_generic_params: 
            #Must be untyped here!
            let generic_param_untyped = newIdentNode(generic_param.strVal())

            #No specification for type declarations
            let new_generic_ident_def = nnkIdentDefs.newTree(
                generic_param_untyped,
                newEmptyNode(),
                newEmptyNode()
            )

            generics_ident_defs.add(new_generic_ident_def)

    #call to old struct
    old_struct_name_export = nnkDotExpr.newTree(
        module_name,
        old_struct_name_export_ident
    )

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

    #Change name in obj_type argument (third last)
    new_struct_formal_params[^3][1][1] = struct_new_name_export_ident

    #Add obj_type, ugen_auto_mem and ugen_call_type etc...
    new_struct_call.add(
        newIdentNode("obj_type"),
        newIdentNode("ugen_auto_mem"),
        newIdentNode("ugen_call_type"),
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

    let new_struct_export = nnkTypeSection.newTree(
        nnkTypeDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                struct_new_name_export_ident
            ),
            generics_ident_defs,
            struct_new_name_ident
        )
    )

    var new_struct_new_inner = nnkProcDef.newTree(
        nnkPostfix.newTree(
            newIdentNode("*"),
            struct_new_name_struct_new_inner_ident
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
        new_struct_export,
        new_struct_new_inner
    )

    #error astGenRepr new_struct
    #error repr result


proc generate_new_modue_bindings_for_def(module_name : NimNode, def_call : NimNode, def_new_name : NimNode, def_combinations : var OrderedTable[string, NimNode]) : NimNode {.compileTime.} =
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
        #ignore autos and ugen_call_type:type in generics!
        if not (generic_param.strVal().endsWith(":type")):
            new_template_generic_params.add(
                nnkIdentDefs.newTree(
                    newIdentNode(generic_param.strVal()),
                    newIdentNode("SomeNumber"), #generics are always SomeNumber (for now)
                    newEmptyNode()
                )
            )

    #If generic params
    if generic_params.len > 1: # 1 because there's always ugen_call_type:type
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
            
            #ImportMe -> ImportMe_module_inner.ImportMe_struct_export
            #[ let inner_type = arg_type.getTypeImpl()
            if inner_type.kind == nnkPtrTy:
                if inner_type[0].strVal().endsWith("_struct_inner"):
                    #is this needed? Os is arg_type enough since it's a symbol?
                    let new_arg_type = parseStmt(module_name.strVal() & "." & arg_type_str & "_struct_export")[0]
            
                    #error astGenRepr new_arg_type  ]#

            #Skip samplerate. bufsize, ugen_auto_mem, ugen_call_type
            if arg_name_str != "samplerate" and arg_name_str != "bufsize" and arg_name_str != "ugen_auto_mem" and arg_name_str != "ugen_call_type":    
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
    #This is only needed to create new def_exports, as templates override each other already 
    let formal_params_repr = repr(new_template_formal_params)
    def_combinations[formal_params_repr] = def_call

    result.add(new_template)

proc generate_new_module_bindings_for_struct_or_def_inner(module_name : NimNode, struct_or_def_typed : NimNode, struct_constructor_typed : NimNode, struct_or_def_new_name : NimNode, def_combinations : var OrderedTable[string, NimNode]) : NimNode {.compileTime.} =
    result = nnkStmtList.newTree()

    let struct_or_def_impl = struct_or_def_typed.getImpl()

    #error astGenRepr struct_or_def_impl

    #Struct
    if struct_or_def_impl.kind == nnkTypeDef:
        let new_struct = generate_new_module_bindings_for_struct(module_name, struct_or_def_impl, struct_constructor_typed, struct_or_def_new_name)
        result.add(new_struct)
    
    #Def
    elif struct_or_def_impl.kind == nnkProcDef:
        let actual_def_call = struct_or_def_impl[^1]

        #multiple ones with same name
        if actual_def_call.kind == nnkOpenSymChoice:
            for def_call in actual_def_call:
                let new_template = generate_new_modue_bindings_for_def(module_name, def_call, struct_or_def_new_name, def_combinations)
                result.add(new_template)
        
        if actual_def_call.kind == nnkSym:
            let new_template = generate_new_modue_bindings_for_def(module_name, actual_def_call, struct_or_def_new_name, def_combinations)
            result.add(new_template)
    
proc generate_new_def_exports(def_combinations : OrderedTable[string, NimNode], def_new_name : NimNode) : NimNode {.compileTime.} =
    result = nnkStmtList.newTree()
    for key, value in def_combinations:
        let 
            def_call = value

            def_new_name_str = def_new_name.strVal()

        #def_dummy
        let 
            def_dummy_name = newIdentNode(def_new_name_str & "_def_dummy")
            def_export = newIdentNode(def_new_name_str & "_def_export")
            
            def_dummy = nnkWhenStmt.newTree(
                nnkElifBranch.newTree(
                    nnkPrefix.newTree(
                        newIdentNode("not"),
                        nnkCall.newTree(
                            newIdentNode("declared"),
                            def_dummy_name
                        )
                    ),
                    nnkStmtList.newTree(
                        nnkProcDef.newTree(
                            nnkPostfix.newTree(
                                newIdentNode("*"),
                                def_dummy_name
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
                                def_export
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

        #actual def_export
        var 
            def_call_typed = def_call.getImpl() #typed
            def_call_typed_formal_params = def_call_typed[3] #save formal params! they are typed and carry all type infos
            new_def_export = parseStmt(repr(def_call_typed))[0] #typed to untyped

        #Change name
        new_def_export[0] = nnkPostfix.newTree(
            newIdentNode("*"),
            def_export
        )

        #If it has generics, need to be SomeNumber! Or type info won't work
        var generic_params = new_def_export[2]
        for generic_param in generic_params:
            generic_param[1] = newIdentNode("SomeNumber")

        #Use typed formal params (so all type information on arguments and return types is preserverd)
        new_def_export[3] = def_call_typed_formal_params

        #Use the actual def_call in order to maintain all type information and module belonging!
        new_def_export[^1] = def_call 

        result.add(
            def_dummy,
            new_def_export
        )

    #echo repr result

macro generate_new_module_bindings_for_struct_or_def*(module_name : untyped, struct_or_def_typed : typed, struct_constructor_typed : typed = nil, struct_or_def_new_name : untyped) : untyped =    
    var def_combinations : OrderedTable[string, NimNode]
    result = nnkStmtList.newTree()

    #error astGenRepr struct_or_def_typed

    if struct_or_def_typed.kind == nnkSym:
        let new_structs_or_def_templates = generate_new_module_bindings_for_struct_or_def_inner(module_name, struct_or_def_typed, struct_constructor_typed, struct_or_def_new_name, def_combinations)
        result.add(new_structs_or_def_templates)
        
    elif struct_or_def_typed.kind == nnkClosedSymChoice:
        result = nnkStmtList.newTree()

        #error astGenRepr struct_or_def_typed
        
        for struct_or_def_choice in struct_or_def_typed:
            let new_structs_or_def_templates = generate_new_module_bindings_for_struct_or_def_inner(module_name, struct_or_def_choice, struct_constructor_typed, struct_or_def_new_name, def_combinations)
            result.add(new_structs_or_def_templates)

    #Only for defs
    let new_def_exports = generate_new_def_exports(def_combinations, struct_or_def_new_name)
    result.add(new_def_exports)

    #error repr result
    

#use Path:
    #Something as Something1 
    #someFunc as someFunc1
macro use*(path : untyped, stmt_list : untyped) : untyped =
    var import_name_without_extension : string

    result = nnkStmtList.newTree()

    var 
        import_stmt = nnkImportExceptStmt.newTree()
        export_stmt = nnkExportExceptStmt.newTree()

    #"ImportMe.omni" or ImportMe
    if path.kind == nnkStrLit or path.kind == nnkIdent:
        import_name_without_extension = path.strVal().splitFile().name
    
    #../../ImportMe
    elif path.kind == nnkPrefix:
        if path.last().kind != nnkIdent:
            error "use: Invalid path syntax: " & repr(path)

        import_name_without_extension = path[^1].strVal()
    else:
        error "use: Invalid path syntax: " & repr(path)

    let import_name_module_inner = newIdentNode(import_name_without_extension & "_module_inner")

    #Add import
    import_stmt.add(
        nnkInfix.newTree(
            newIdentNode("as"),
            path,
            import_name_module_inner
        )
    )

    #Add export
    export_stmt.add(
        import_name_module_inner
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
            let infix_ident = statement[0]
            if infix_ident.strVal() == "as":
                let 
                    infix_first_val = statement[1]
                    infix_second_val = statement[2]

                var generate_new_module_bindings_for_struct_or_def_call = nnkCall.newTree(
                    newIdentNode("generate_new_module_bindings_for_struct_or_def"),
                    import_name_module_inner,
                )

                #Add excepts: first entry of infix
                if infix_first_val.kind == nnkIdent:
                    let 
                        infix_first_val_struct_export = newIdentNode(infix_first_val.strVal() & "_struct_export")
                        infix_first_val_struct_new_inner = newIdentNode(infix_first_val.strVal() & "_struct_new_inner")
                    
                    import_stmt.add(infix_first_val)
                    import_stmt.add(infix_first_val_struct_export)
                    export_stmt.add(infix_first_val)
                    export_stmt.add(infix_first_val_struct_export)

                    let 
                        struct_dot_expr = nnkDotExpr.newTree(
                            import_name_module_inner,
                            infix_first_val_struct_export
                        )

                        struct_constructor_dot_expr = nnkDotExpr.newTree(
                            import_name_module_inner,
                            infix_first_val_struct_new_inner
                        )

                        def_dot_expr = nnkDotExpr.newTree(
                            import_name_module_inner,
                            newIdentNode(infix_first_val.strVal() & "_def_export")
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
                                        newLit("Undefined identifier '" & infix_first_val.strVal() & "' in '" & repr(statement) & "'")
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
                                        newLit("Undefined constructor '" & infix_first_val_struct_new_inner.strVal() & "' in '" & repr(statement) & "'")
                                    )
                                )
                            )
                        )

                    #when_statement_struct_constructor_typed = newNilLit()

                    #When statement: if it's a struct, gonna pass that. Otherwise, gonna pass the def if it's defined
                    generate_new_module_bindings_for_struct_or_def_call.add(
                        when_statement_struct_typed,
                        when_statement_struct_constructor_typed
                    )

                #elif dot expr
                elif infix_first_val.kind == nnkDotExpr:
                    error "use: Import with submodules is not yet implemented: " & repr(infix_first_val)
                
                else:
                    error "use: Invalid first infix value: " & repr(infix_first_val)

                #Add the structs / defs to check: second entry of infix
                if infix_second_val.kind == nnkIdent:
                    generate_new_module_bindings_for_struct_or_def_call.add(
                        infix_second_val
                    )

                    result.add(
                        generate_new_module_bindings_for_struct_or_def_call
                    )

                else:
                    error "use: Invalid second infix value :" & repr(infix_second_val)
            else:
                error "use: Invalid infix: " & repr(infix_ident)
        else:
            error "use: Invalid infix syntax: " & repr(statement)

    #error repr result

#use Path
#OR
#use Path1, Path2, Path3
macro use*(paths : varargs[untyped]) : untyped =
    error astGenRepr paths