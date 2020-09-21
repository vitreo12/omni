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

import macros, os

macro generate_new_module_bindings_for_struct_or_def*(module_name : untyped, struct_or_def_typed : typed, struct_or_def_new_name : untyped) : untyped =
    #echo astGenRepr struct_or_def_typed
    if struct_or_def_typed.kind == nnkSym:
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
                    echo astGenRepr def_call.getImpl()
            
            elif actual_def_call.kind == nnkSym:
                echo astGenRepr actual_def_call.getImpl()
    
    #echo repr struct_or_def_typed

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