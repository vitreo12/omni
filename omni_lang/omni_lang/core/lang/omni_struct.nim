import macros

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
        
        proc_def             = nnkProcDef.newTree()      #the innerInit* proc
        proc_formal_params   = nnkFormalParams.newTree() #the whole [T](args..) : returntype 
        proc_body            = nnkStmtList.newTree()     #body of the proc
        
        template_def = nnkTemplateDef.newTree()          #the new* template
        template_formal_params : NimNode
        template_body_call = nnkCall.newTree()
    
    var 
        obj_name : NimNode
        ptr_name : NimNode

        generics = nnkGenericParams.newTree()          #If generics are present in struct definition
        generics_proc_def = nnkGenericParams.newTree() #These are all the generics that will be set to be T : SomeNumber, instead of just T

        obj_bracket_expr : NimNode
        ptr_bracket_expr : NimNode

    #The name of the function with the asterisk, in case of supporting modules in the future
    #proc innerInit
    proc_def.add(
        nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode("innerInit")
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

                #If [T : Something etc...]
                else:
                    error($ptr_name.strVal() & $ "\'s generic type \"" & $(child[0].strVal()) & "\" contains subtypes. These are not supported. Struct's generic types are defaulted to only be SomeNumber.")
            
        #Add generics to obj type
        obj_type_def.add(generics)

        #Add generics to ptr type
        ptr_type_def.add(generics)

        #Add generics to proc definition. (proc init*[T : SomeNumber, Y : SomeNumber]...) These will have added the ": SomeNumber" on each generic.
        proc_def.add(generics_proc_def)

        #Add generics to template definition
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

        #Add one more empty node (needed when no generics)
        proc_def.add(
            newEmptyNode()
        )

        #Add one more empty node (needed when no generics)
        template_def.add(
            newEmptyNode()
        )

        #Add the Phasor_obj[T, Y] to ptr_ty, for object that the pointer points at.
        ptr_ty.add(obj_name)

        #When not using generics, the sections where the bracket generic expression is used are just the normal name of the type
        obj_bracket_expr = obj_name
        ptr_bracket_expr = ptr_name

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

    #add innerInit func and ptr name to template's call statement (calling innerInit) using "obj_type"
    template_body_call.add(newIdentNode("innerInit"))
    template_body_call.add(newIdentNode("obj_type"))

    #Loop over struct's body
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

        new_decl.add(var_name)
        new_decl.add(var_type)
        new_decl.add(newEmptyNode())

        rec_list.add(new_decl)

        #Add to arg list for innerInit proc
        proc_formal_params.add(
            nnkIdentDefs.newTree(
                var_name,
                var_type,
                newEmptyNode()
            )
        )

        #Add result.phase = phase, etc... assignments
        proc_body.add(
            nnkAsgn.newTree(
                nnkDotExpr.newTree(
                    newIdentNode("result"),
                    var_name
                ),
                var_name
            )
        )

        #Add the list of var names to the template's innerInit function call
        template_body_call.add(var_name)
    
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
    
    # ============== #
    # INNERINIT PROC #
    # ============== #
    
    #Add ugen_auto_mem : ptr OmniAutoMem as last argument
    proc_formal_params.add(
        nnkIdentDefs.newTree(
            newIdentNode("ugen_auto_mem"),
            nnkPtrTy.newTree(
                newIdentNode("OmniAutoMem")
            ),
            newEmptyNode()
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

    #re-use proc's formal params, but replace the fist entry (return type) with untyped and remove last entry, which is the ugen_auto_mem argument
    template_formal_params = proc_formal_params.copy
    template_formal_params.del(template_formal_params.len - 1)
    template_formal_params[0] = newIdentNode("untyped")
    template_def.add(template_formal_params)
    template_def.add(newEmptyNode())
    template_def.add(newEmptyNode())

    #echo repr template_formal_params

    #Add function ugen_auto_mem to template call (it's the last argument for the innerInit proc)
    template_body_call.add(newIdentNode("ugen_auto_mem"))

    #Add body (just call _inner proc, adding "ugen_auto_mem" at the end)
    template_def.add(
        template_body_call
    )
    
    #Add template to result
    final_stmt_list.add(template_def)
    
    #If returning without quote, it bugs. Needs to be returned like this to be working properly. don't know why.
    return quote do:
        `final_stmt_list`