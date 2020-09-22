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

import macros, os, strutils

proc generate_new_modue_bindings_def(module_name : NimNode, def_call : NimNode, def_new_name : NimNode) : NimNode {.compileTime.} =
    result = nnkStmtList.newTree()

    let 
        def_call_proc_def_typed = def_call.getImpl()
        generic_params = def_call_proc_def_typed[2]
        formal_params = def_call_proc_def_typed[3]

    var
        new_template_generic_params_ident_defs = nnkIdentDefs.newTree()
        new_template_generic_params = nnkGenericParams.newTree(
            new_template_generic_params_ident_defs
        )
        
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

        new_def_export_call : NimNode

    for generic_param in generic_params:
        #ignore autos and ugen_call_type:type
        if not (generic_param.strVal().endsWith(":type")):
            new_template_generic_params_ident_defs.add(
                newIdentNode(generic_param.strVal())
            )

    #If generic params
    if generic_params.len > 1:
        new_template_generic_params_ident_defs.add(
            newEmptyNode(),
            newEmptyNode()
        )

        new_template.add(new_template_generic_params)
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
            let inner_type = arg_type.getTypeImpl()
            if inner_type.kind == nnkPtrTy:
                if inner_type[0].strVal().endsWith("_struct_inner"):
                    let new_arg_type = parseStmt(module_name.strVal() & "." & arg_type_str & "_struct_export")[0]
            
                    #error astGenRepr new_arg_type 

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
        
    #echo repr new_template

    new_def_export_call = parseStmt(repr(def_call_proc_def_typed))

    new_def_export_call[0][0] = nnkPostfix.newTree(
        newIdentNode("*"),
        newIdentNode(def_new_name.strVal() & "_def_export")
    )
    
    new_def_export_call[0][^1] = nnkStmtList.newTree(
        def_call
    )
    
    #error repr parseStmt(repr(new_def_export_call))

    result.add(new_template)
    #result.add(new_def_export_call)

    #error repr result

proc generate_new_module_bindings_for_struct_or_def_inner(module_name : NimNode, struct_or_def_typed : NimNode, struct_or_def_new_name : NimNode) : NimNode {.compileTime.} =
    result = nnkStmtList.newTree()

    let struct_or_def_impl = struct_or_def_typed.getImpl()

    #Struct
    if struct_or_def_impl.kind == nnkTypeDef:
        discard
    
    #Def
    elif struct_or_def_impl.kind == nnkProcDef:
        let actual_def_call = struct_or_def_impl[^1]

        #multiple ones with same name
        if actual_def_call.kind == nnkOpenSymChoice:
            for def_call in actual_def_call:
                let new_template = generate_new_modue_bindings_def(module_name, def_call, struct_or_def_new_name)
                result.add(new_template)
        
        if actual_def_call.kind == nnkSym:
            let new_template = generate_new_modue_bindings_def(module_name, actual_def_call, struct_or_def_new_name)
            result.add(new_template)
    
    

macro generate_new_module_bindings_for_struct_or_def*(module_name : untyped, struct_or_def_typed : typed, struct_or_def_new_name : untyped) : untyped =    
    if struct_or_def_typed.kind == nnkSym:
        result = generate_new_module_bindings_for_struct_or_def_inner(module_name, struct_or_def_typed, struct_or_def_new_name)
        
    elif struct_or_def_typed.kind == nnkClosedSymChoice:
        result = nnkStmtList.newTree()

        #error astGenRepr struct_or_def_typed
        
        for struct_or_def_choice in struct_or_def_typed:
            let new_templates = generate_new_module_bindings_for_struct_or_def_inner(module_name, struct_or_def_choice, struct_or_def_new_name)
            result.add(new_templates)

    echo repr result
    


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
            error "use: Invalid path syntax " & repr(path)

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
                    let infix_first_val_struct_export = newIdentNode(infix_first_val.strVal() & "_struct_export")
                    
                    import_stmt.add(infix_first_val)
                    import_stmt.add(infix_first_val_struct_export)
                    export_stmt.add(infix_first_val)
                    export_stmt.add(infix_first_val_struct_export)

                    let struct_case = nnkDotExpr.newTree(
                        import_name_module_inner,
                        infix_first_val_struct_export
                    )

                    let def_case = nnkDotExpr.newTree(
                        import_name_module_inner,
                        newIdentNode(infix_first_val.strVal() & "_def_export")
                    )

                    var when_statement = nnkWhenStmt.newTree(
                        nnkElifBranch.newTree(
                            nnkCall.newTree(
                                newIdentNode("declared"),
                                struct_case
                            ),
                            struct_case
                        ),
                        nnkElifBranch.newTree(
                            nnkCall.newTree(
                                newIdentNode("declared"),
                                def_case
                            ),
                            def_case
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

                    #When statement: if it's a struct, gonna pass that. Otherwise, gonna pass the def if it's defined
                    generate_new_module_bindings_for_struct_or_def_call.add(
                        when_statement
                    )

                #elif dot expr
                elif infix_first_val.kind == nnkDotExpr:
                    error "dot expr not yet"
                
                else:
                    error "use: Invalid first infix value :" & repr(infix_first_val)

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