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

import macros, omni_type_checker, omni_macros_utilities

macro struct*(struct_name : untyped, code_block : untyped) : untyped =
    var 
        final_stmt_list = nnkStmtList.newTree()          #return statement
        type_section    = nnkTypeSection.newTree()       #the whole type section (both _obj and ptr)
        obj_type_def    = nnkTypeDef.newTree()           #the Phasor_obj block
        obj_ty          = nnkObjectTy.newTree(           #the body of the Phasor_obj 
            newEmptyNode(),  
            newEmptyNode()
        )      
        rec_list        = nnkRecList.newTree()           #the variable declaration section of Phasor_obj
        
        ptr_type_def    = nnkTypeDef.newTree()           #the Phasor = ptr Phasor_obj block
        ptr_ty          = nnkPtrTy.newTree()             #the ptr type expressing ptr Phasor_obj

        generics_seq : seq[NimNode]
        checkValidTypes = nnkStmtList.newTree()        #Check that types fed to struct are correct omni types
    
    var 
        obj_name : NimNode
        ptr_name : NimNode

        generics = nnkGenericParams.newTree()          #If generics are present in struct definition

        obj_bracket_expr : NimNode
        #ptr_bracket_expr : NimNode

    #Using generics
    if struct_name.kind == nnkBracketExpr:
        obj_name = newIdentNode($(struct_name[0].strVal()) & "_obj")  #Phasor_obj
        ptr_name = struct_name[0]                                     #Phasor

        #If struct name doesn't start with capital letter, error out
        if not(ptr_name.strVal[0] in {'A'..'Z'}):
            error("struct \"" & $ptr_name & $ "\" must start with a capital letter")

        #NOTE THE DIFFERENCE BETWEEN obj_type_def here with generics and without, different number of newEmptyNode()
        #Add name to obj_type_def (with asterisk, in case of supporting modules in the future)
        obj_type_def.add(nnkPostfix.newTree(
                newIdentNode("*"),
                obj_name
            )
        )

        #NOTE THE DIFFERENCE BETWEEN ptr_type_def here with generics and without, different number of newEmptyNode()
        #Add name to ptr_type_def (with asterisk, in case of supporting modules in the future)
        ptr_type_def.add(nnkPostfix.newTree(
                newIdentNode("*"),
                ptr_name
            )
        )

        #Initialize them to be bracket expressions and add the "Phasor_obj" and "Phasor" names to brackets
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
                    ##Also add the name of the generic to the Phasor_obj[T, Y...]
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

        #Add the Phasor_obj[T, Y] to ptr_ty, for object that the pointer points at.
        ptr_ty.add(obj_bracket_expr)

    #No generics, just name of struct
    elif struct_name.kind == nnkIdent:
        obj_name = newIdentNode($(struct_name) & "_obj")              #Phasor_obj
        ptr_name = struct_name                                        #Phasor

        #If struct name doesn't start with capital letter, error out
        if not(ptr_name.strVal[0] in {'A'..'Z'}):
            error("struct \"" & $ptr_name & $ "\" must start with a capital letter")
        
        #Add name to obj_type_def (with asterisk, in case of supporting modules in the future)
        obj_type_def.add(nnkPostfix.newTree(
                newIdentNode("*"),
                obj_name
            ),
            newEmptyNode()
        )

        #Add name to ptr_type_def (with asterisk, in case of supporting modules in the future)
        ptr_type_def.add(nnkPostfix.newTree(
                newIdentNode("*"),
                ptr_name
            ),
            newEmptyNode()
        )

        #Add the Phasor_obj[T, Y] to ptr_ty, for object that the pointer points at.
        ptr_ty.add(obj_name)

        #When not using generics, the sections where the bracket generic expression is used are just the normal name of the type
        obj_bracket_expr = obj_name
        #ptr_bracket_expr = ptr_name

    #Loop over struct's body
    for code_stmt in code_block:
        let code_stmt_kind = code_stmt.kind

        var 
            var_name : NimNode
            var_type : NimNode
            new_decl = nnkIdentDefs.newTree()

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

        new_decl.add(
            nnkPostfix.newTree(
                newIdentNode("*"),
                var_name
            ),
            var_type,
            newEmptyNode()
        )

        rec_list.add(new_decl)

        var var_type_is_generic = false

        #Check if any of the argument is a generic (e.g, phase T, freq Y)
        if generics_seq.len > 0:
            if var_type in generics_seq:
                var_type_is_generic = true

        #only add check for current type if is not a generic one
        if not var_type_is_generic: 
            #This is a struct that has generics in it (e.g, Phasor[T])
            var var_type_without_generics : NimNode
            if var_type.kind == nnkBracketExpr:
                var_type_without_generics = var_type[0]
            else:
                var_type_without_generics = var_type

            #Add validity type checks to output.
            checkValidTypes.add(
                nnkCall.newTree(
                    newIdentNode("checkValidType_macro"),
                    var_type_without_generics,
                    newLit(var_name.strVal()), 
                    newLit(false),
                    newLit(false),
                    newLit(true),
                    newLit(ptr_name.strVal())
                )
            )
    
    # ================================ #
    # Add all things related to object #
    # ================================ #

    #Add var : type declarations to obj declaration
    obj_ty.add(rec_list)
    
    #Add the obj declaration (the nnkObjectTy) to the type declaration
    obj_type_def.add(obj_ty)
    
    #Add the type declaration of Phasor_obj to the type section
    type_section.add(obj_type_def)
    
    # ================================= #
    # Add all things related to pointer #
    # ================================= #
    
    #Add the ptr_ty inners to ptr_type_def
    ptr_type_def.add(ptr_ty)
    
    #Add the type declaration of Phasor to type section
    type_section.add(ptr_type_def)

    #Add the whole type section to result
    final_stmt_list.add(type_section)

    #The init_struct macro, which will declare the "proc struct_init_inner ..." and the "template new ..."
    let struct_create_init_proc_and_template = nnkCall.newTree(
        newIdentNode("struct_create_init_proc_and_template"),
        ptr_name
    )

    let findDatasAndStructs = nnkCall.newTree(
        newIdentNode("findDatasAndStructs"),
        ptr_name
    )
    
    return quote do:
        `checkValidTypes`
        `final_stmt_list`
        `struct_create_init_proc_and_template`
        `findDatasAndStructs`

#Declare the "proc struct_init_inner ..." and the "template new ...", doing all sorts of type checks
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
        generics : seq[string]

    var 
        obj_bracket_expr : NimNode
        ptr_bracket_expr : NimNode

        generics_proc_def    = nnkGenericParams.newTree() #These are all the generics that will be set to be T : SomeNumber, instead of just T

        proc_def             = nnkProcDef.newTree()      #the struct_init_inner* proc
        proc_formal_params   = nnkFormalParams.newTree() #the whole [T](args..) : returntype 
        proc_body            = nnkStmtList.newTree()     #body of the proc
        
        template_def = nnkTemplateDef.newTree()          #the new* template
        template_formal_params : NimNode
        template_body_call = nnkCall.newTree()

    #The name of the function with the asterisk, in case of supporting modules in the future
    #proc struct_init_inner
    proc_def.add(
        nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode("struct_init_inner")
        ),
        newEmptyNode()
    )

    #Add name with * for export
    #template new
    template_def.add(
        nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode("new")
        ),
        newEmptyNode()
    )

    #Generics
    if obj_struct_name_kind == nnkBracketExpr:
        let obj_struct_name_ident = obj_struct_name[0]
        obj_struct_type = (obj_struct_name_ident).getTypeImpl()

        #Initialize them to be bracket expressions and add the "Phasor_obj" and "Phasor" names to brackets
        obj_bracket_expr = nnkBracketExpr.newTree(obj_struct_name[0])
        ptr_bracket_expr = nnkBracketExpr.newTree(ptr_struct_name)

        #Retrieve generics
        for index, generic_val in obj_struct_name.pairs():
            if index == 0:
                continue

            ##Also add the name of the generic to the Phasor_obj[T, Y...]
            obj_bracket_expr.add(generic_val)

            #Also add the name of the generic to the Phasor[T, Y...]
            ptr_bracket_expr.add(generic_val)

            var generic_proc_proc_def = nnkIdentDefs.newTree()
            generic_proc_proc_def.add(generic_val)
            generic_proc_proc_def.add(newIdentNode("SomeNumber"))  #add ": SomeNumber" to the generic type
            generic_proc_proc_def.add(newEmptyNode())
            generics_proc_def.add(generic_proc_proc_def)
            
            generics.add(generic_val.strVal())

        #Add generics to proc definition. (proc init*[T : SomeNumber, Y : SomeNumber]...) These will have added the ": SomeNumber" on each generic.
        proc_def.add(generics_proc_def)

        #Add generics to template definition
        template_def.add(generics_proc_def)

    #no generics
    else:
        obj_struct_type = obj_struct_name.getTypeImpl()

        #Add one more empty node (needed when no generics)
        proc_def.add(
            newEmptyNode()
        )

        #Add one more empty node (needed when no generics)
        template_def.add(
            newEmptyNode()
        )

        #When not using generics, the sections where the bracket generic expression is used are just the normal name of the type
        obj_bracket_expr = obj_struct_name
        ptr_bracket_expr = ptr_struct_name

    #Add Phasor[T, Y] return type
    proc_formal_params.add(ptr_bracket_expr)

    #Add first argument: obj_type : typedesc[Phasor[T, Y]]
    proc_formal_params.add(
        nnkIdentDefs.newTree(
            newIdentNode("obj_type"),
            nnkBracketExpr.newTree(
                newIdentNode("typedesc"),
                ptr_bracket_expr
            ),
            newEmptyNode()
        )   
    )

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
                            newLit("attempting to allocate memory in the `perform` or `sample` blocks for `struct " & ptr_name & "`")
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

    #add struct_init_inner func and ptr name to template's call statement (calling struct_init_inner) using "obj_type"
    template_body_call.add(newIdentNode("struct_init_inner"))
    template_body_call.add(newIdentNode("obj_type"))

    let struct_fields = obj_struct_type[2]

    for index, field in struct_fields:
        assert field.len == 3
        
        var 
            field_name = field[0]
            field_type = field[1]

        var field_type_without_generics = field_type
        
        if field_type.kind == nnkBracketExpr:
            field_type_without_generics = field_type[0]
    
        let 
            field_is_struct  = field_type_without_generics.isStruct(true)
            field_is_generic = field_type_without_generics.strVal() in generics

        var 
            arg_field_type = field_type
            arg_field_value = newEmptyNode()
        
        if not(field_is_struct) and not(field_is_generic):
            arg_field_type = newIdentNode("auto")
        
        if not(field_is_struct):
            arg_field_value = newIntLitNode(0)

        #Add to arg list for struct_init_inner proc
        proc_formal_params.add(
            nnkIdentDefs.newTree(
                field_name,
                arg_field_type,
                arg_field_value
            )
        )

        #Add result.phase = phase, etc... assignments
        if field_is_struct or field_is_generic:
            proc_body.add(
                nnkAsgn.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("result"),
                        field_name
                    ),
                    field_name
                )
            )

        #If it's not a struct, convert the value too
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

        #Add the list of var names to the template's struct_init_inner function call
        template_body_call.add(field_name)

    # ====================== #
    # STRUCT_INIT_INNER PROC #
    # ====================== #
    
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
    proc_def.add(nnkPragma.newTree(
            newIdentNode("inline")
        ),
        newEmptyNode()
    )
    
    #Add the function body to the proc declaration
    proc_def.add(proc_body)

    #Add proc to result
    final_stmt_list.add(proc_def)

    # ============ #
    # NEW TEMPLATE #
    # ============ #

    #re-use proc's formal params, but replace the fist entry (return type) with untyped and remove last two entries, which are ugen_auto_mem and ugen_call_type
    template_formal_params = proc_formal_params.copy
    template_formal_params.del(template_formal_params.len - 1) #delete ugen_call_type
    template_formal_params.del(template_formal_params.len - 1) #table shifted, delete ugen_auto_mem now
    template_formal_params[0] = newIdentNode("untyped")
    template_def.add(template_formal_params)
    template_def.add(newEmptyNode())
    template_def.add(newEmptyNode())

    #Add function ugen_auto_mem / ugen_call_type to template call
    template_body_call.add(
        newIdentNode("ugen_auto_mem"),
        newIdentNode("ugen_call_type")
    )

    #Add body (just call _inner proc, adding "ugen_auto_mem" and "ugen_call_type" at the end)
    template_def.add(
        template_body_call
    )
    
    #Add template to result
    final_stmt_list.add(template_def)

    #Convert the typed statement to an untyped one
    let final_stmt_list_untyped = typedToUntyped(final_stmt_list)
    
    return quote do:
        `final_stmt_list_untyped`