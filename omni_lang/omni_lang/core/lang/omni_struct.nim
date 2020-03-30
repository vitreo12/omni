import macros

macro struct*(struct_name : untyped, code_block : untyped) : untyped =
    var 
        final_stmt_list = nnkStmtList.newTree()
        type_section    = nnkTypeSection.newTree()
        obj_type_def    = nnkTypeDef.newTree()      #the Phasor_obj block
        obj_ty          = nnkObjectTy.newTree()     #the body of the Phasor_obj   
        rec_list        = nnkRecList.newTree()      #the variable declaration section of Phasor_obj
        
        ptr_type_def    = nnkTypeDef.newTree()      #the Phasor = ptr Phasor_obj block
        ptr_ty          = nnkPtrTy.newTree()        #the ptr type expressing ptr Phasor_obj
        
        new_proc_def        = nnkProcDef.newTree()      #the innerInit* function
        new_formal_params   = nnkFormalParams.newTree()
        new_fun_body        = nnkStmtList.newTree()

        template_def = nnkTemplateDef.newTree()   #the new* template
        template_formal_params : NimNode
        template_body = nnkCall.newTree()

    obj_ty.add(newEmptyNode())
    obj_ty.add(newEmptyNode())
    
    var 
        obj_name : NimNode
        ptr_name : NimNode
        generics = nnkGenericParams.newTree()  #If generics are present in struct definition
        generics_proc_def = nnkGenericParams.newTree() #These are all the generics that will be set to be T : SomeNumber, instead of just T

        obj_bracket_expr : NimNode
        ptr_bracket_expr : NimNode

        var_names : seq[NimNode]
        var_types : seq[NimNode]
    
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

        #The name of the function with the asterisk, in case of supporting modules in the future
        #Note that new_proc_def for generics has just one newEmptyNode()
        new_proc_def.add(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("innerInit")
            ),
            newEmptyNode()
        )

        #Add name with * for export
        template_def.add(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("new")
            ),
            newEmptyNode()
        )

        #add innerInit func and ptr name
        template_body.add(newIdentNode("innerInit"))
        template_body.add(ptr_name)

        #Initialize them to be bracket expressions
        obj_bracket_expr = nnkBracketExpr.newTree()
        ptr_bracket_expr = nnkBracketExpr.newTree()

        #Add the "Phasor_obj" and "Phasor" names to brackets
        obj_bracket_expr.add(obj_name)
        ptr_bracket_expr.add(ptr_name)

        for index, child in struct_name:
            if index == 0:
                continue
            else:
                var 
                    generic_proc = nnkIdentDefs.newTree()
                    generic_proc_proc_def = nnkIdentDefs.newTree()
                    
                #If singular [T]
                if child.len() == 0:
                    ##Also add the name of the generic to the Phasor_obj[T, Y...]
                    obj_bracket_expr.add(child)

                    #Also add the name of the generic to the Phasor[T, Y...]
                    ptr_bracket_expr.add(child)

                    generic_proc.add(child)
                    generic_proc_proc_def.add(child)

                    generic_proc.add(newEmptyNode())
                    generic_proc_proc_def.add(newIdentNode("SomeNumber"))  #add ": SomeNumber" to the generic type

                    generic_proc.add(newEmptyNode())
                    generic_proc_proc_def.add(newEmptyNode())

                    generics.add(generic_proc)
                    generics_proc_def.add(generic_proc_proc_def)

                #If [T : SomeFloat or SomeInteger... etc...]
                else:
                    error($ptr_name.strVal() & $ "\'s generic type \"" & $(child[0].strVal()) & "\" contains subtypes. These are not supported. Struct's generic types are defaulted to only be SomeNumber.")

                    #This works, but it's better to not to use it.
                    #[ #All the generics (including the "or" infixes, etc...)
                    for inner_index, inner_child in child:

                        #Add the name of the generics to a table, to be used for ptr
                        if inner_index == 0:
                            obj_bracket_expr.add(inner_child)
                            ptr_bracket_expr.add(inner_child)
                        
                        generic_proc.add(inner_child)
                    
                    generic_proc.add(newEmptyNode())
                    generics.add(generic_proc) ]#
            
        #Add generics to obj type
        obj_type_def.add(generics)

        #Add generics to ptr type
        ptr_type_def.add(generics)

        #Add generics to proc definition. (proc init*[T : SomeNumber, Y : SomeNumber]...) These will have added the ": SomeNumber" on each generic.
        new_proc_def.add(generics_proc_def)

        template_def.add(generics_proc_def)
        
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

        #The name of the function with the asterisk, in case of supporting modules in the future
        new_proc_def.add(nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("innerInit")
            ),
            newEmptyNode(),
            newEmptyNode()
        )

        #Add name with * for export
        template_def.add(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("new")
            ),
            newEmptyNode()
        )

        #needs an extra empty node, go figure
        template_def.add(newEmptyNode())

        #add innerInit func and ptr name
        template_body.add(newIdentNode("innerInit"))
        template_body.add(ptr_name)

        #Add the Phasor_obj[T, Y] to ptr_ty, for object that the pointer points at.
        ptr_ty.add(obj_name)

        #When not using generics, the sections where the bracket generic expression is used are just the normal name of the type
        obj_bracket_expr = obj_name
        ptr_bracket_expr = ptr_name

    for code_stmt in code_block:
        let code_stmt_kind = code_stmt.kind

        var 
            var_name : NimNode
            var_type : NimNode
            new_decl = nnkIdentDefs.newTree()

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

        var_names.add(var_name)
        var_types.add(var_type)

        new_decl.add(var_name)
        new_decl.add(var_type)
        new_decl.add(newEmptyNode())

        rec_list.add(new_decl)

        #Add the list of var names to the template
        template_body.add(var_name)
    
    ####################################
    # Add all things related to object #
    ####################################

    #Add var : type declarations to obj declaration
    obj_ty.add(rec_list)
    
    #Add the obj declaration (the nnkObjectTy) to the type declaration
    obj_type_def.add(obj_ty)
    
    #Add the type declaration of Phasor_obj to the type section
    type_section.add(obj_type_def)
    
    #####################################
    # Add all things related to pointer #
    #####################################
    
    #Add the ptr_ty inners to ptr_type_def
    ptr_type_def.add(ptr_ty)
    
    #Add the type declaration of Phasor to type section
    type_section.add(ptr_type_def)

    #Add the whole type section to result
    final_stmt_list.add(type_section)
    
    ################
    # INIT SECTION #
    ################
    
    #Add Phasor[T, Y] return type
    new_formal_params.add(ptr_bracket_expr)

    #Add obj_type : typedesc[Phasor[T, Y]]
    new_formal_params.add(nnkIdentDefs.newTree(
            newIdentNode("obj_type"),
            nnkBracketExpr.newTree(
                newIdentNode("typedesc"),
                ptr_bracket_expr
            ),
            newEmptyNode()
        )   
    )

    #Add args to function
    for index, var_name in var_names:
        var new_arg = nnkIdentDefs.newTree(
            var_name,
            var_types[index],
            newEmptyNode()
        )

        new_formal_params.add(new_arg)

    #Add ugen_auto_mem : ptr OmniAutoMem
    new_formal_params.add(nnkIdentDefs.newTree(
            newIdentNode("ugen_auto_mem"),
            nnkPtrTy.newTree(
                newIdentNode("OmniAutoMem")
            ),
            newEmptyNode()
        )
    )

    new_proc_def.add(new_formal_params)

    new_proc_def.add(nnkPragma.newTree(
            newIdentNode("inline")
        )
    )

    new_proc_def.add(newEmptyNode())

    #Cast and rtalloc operators
    new_fun_body.add(
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

    #Add result to ugen_auto_mem
    new_fun_body.add(
        nnkCall.newTree(
            newIdentNode("registerChild"),
            newIdentNode("ugen_auto_mem"),
            newIdentNode("result")
        )
    )

    #Add result.phase = phase, etc..
    for index, var_name in var_names:
        new_fun_body.add(
            nnkAsgn.newTree(
                nnkDotExpr.newTree(
                    newIdentNode("result"),
                    var_name
                ),
                var_name
            )
        )
    
    #Add the function body to the proc declaration
    new_proc_def.add(new_fun_body)

    # TEMPLATE
    

    template_formal_params = new_formal_params.copy
    template_formal_params.del(template_formal_params.len - 1)
    template_formal_params[0] = newIdentNode("untyped")
    template_def.add(template_formal_params)
    template_def.add(newEmptyNode())
    template_def.add(newEmptyNode())

    #echo repr template_formal_params

    #Add function ugen_auto_mem to template call
    template_body.add(newIdentNode("ugen_auto_mem"))
    
    #Add body (just call _inner proc, adding "ugen_auto_mem" at the end)
    template_def.add(
        nnkStmtList.newTree(
            template_body
        )
    )
    
    #Add everything to result
    final_stmt_list.add(new_proc_def)

    final_stmt_list.add(template_def)
    
    #If using result, it was bugging. Needs to be returned like this to be working properly. don't know why.
    return quote do:
        `final_stmt_list`