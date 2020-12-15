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

import macros, strutils

#Import the compile time list of float parameters to be added to Omni_UGen
from omni_io import omni_params_names_list, omni_params_defaults_list, omni_buffers_names_list

#Not needed with nim >= 1.4
when (NimMajor, NimMinor) < (1, 4):
    #being the argument typed, the code_block is semantically executed after parsing, making it to return the correct result out of the "build" statement
    macro omni_execute_build_statement_and_create_ugen_obj(code_block : typed) : untyped =  
        discard

#the "pre_init" argument is used at the start of "init" so that fictional let variables are declared
#in order to make Nim's parsing happy (just as with bufsize, samplerate, etc...)
macro omni_unpack_ins_init*(ins_names : typed, pre_init : typed = false) : untyped =
    result = nnkStmtList.newTree()

    let 
        ins_names_seq = ins_names.getImpl.strVal.split(',')
        pre_init_bool = pre_init.boolVal()
    
    for i, in_name in ins_names_seq:
        let in_number_name = ("in" & $(i+1))

        #let_statement will be overwritten if needed
        var
            ident_defs : NimNode
            
            let_statement = nnkDiscardStmt.newTree(
                newEmptyNode()
            )
        
        #Ignore in1, in2, etc...
        if in_name != in_number_name:
            var ident_val = newIdentNode(in_number_name)

            ident_defs = nnkIdentDefs.newTree()
            let_statement = nnkLetSection.newTree(ident_defs)
            
            if pre_init_bool == true:
                ident_val = newLit(0.0)

            ident_defs.add(
                newIdentNode(in_name),
                newEmptyNode(),
                ident_val
            )

        #Check for no {Buffer} on current in1, in2, etc...
        #The {Buffer} case is handled in the "add_buffers_ins" macro
        let when_statement = nnkWhenStmt.newTree(
            nnkElifBranch.newTree(
                nnkPrefix.newTree(
                    newIdentNode("not"),
                    nnkCall.newTree(
                        newIdentNode("declared"),
                        newIdentNode(in_number_name & "_omni_buffer")
                    )
                ),
                nnkStmtList.newTree(
                    let_statement
                )
            )
        )  

        result.add(when_statement)

#This has been correctly parsed!
macro omni_init_inner*(code_block_stmt_list : untyped) : untyped =
    #Extract the actual parsed code_block from the nnkStmtList
    let code_block = code_block_stmt_list[0]

    var 
        #They both are nnkIdentNodes
        let_declarations : seq[NimNode]
        var_declarations : seq[NimNode]

        templates_for_perform_var_declarations     = nnkStmtList.newTree()
        templates_for_constructor_var_declarations = nnkStmtList.newTree()
        templates_for_constructor_let_declarations = nnkStmtList.newTree()
        perform_build_names_table_static_stmt      = nnkStmtList.newTree()
        perform_build_names_table_static           = nnkStaticStmt.newTree(
            perform_build_names_table_static_stmt
        )

        call_to_build_macro : NimNode
        final_var_names = nnkBracket.newTree()
        assign_ugen_fields = nnkStmtList.newTree()

        new_call_provided = false
    
    #Look if "build" macro call is the last statement in the block.
    let code_block_last = code_block.last()
    if code_block_last.kind == nnkCall or code_block_last.kind == nnkCommand:
        if code_block_last[0].strVal() == "build":
            new_call_provided = true

    #[
        REDUCE ALL THESE FOR LOOPS IN A BETTER WAY!!
    ]#

    #Loop over all the statements in code_block, looking for "var" and "let" declarations
    for outer_index, statement in code_block:
        #var statements
        if statement.kind == nnkVarSection:
            for inner_index, var_declaration in statement:
                let 
                    var_declaration_name = var_declaration[0]
                    new_var_declaration = newIdentNode($(var_declaration[0].strVal()) & "_var")

                #Add the ORIGINAL ident name to the array, modifying its name to be "variableName_var"
                var_declarations.add(var_declaration_name)

                #Then, modify the field in the code_block to be "variableName_var"
                code_block[outer_index][inner_index][0] = new_var_declaration

                #[
                    RESULT:
                    template phase() : untyped {.dirty.} =    #The untyped here is fundamental to make this act like a normal text replacement.
                        phase_var
                ]#                
                #Construct a template that replaces the "variableName" in code with "variableName_var", to be used in constructor for correct namings
                let constructor_var_template = nnkTemplateDef.newTree(
                    var_declaration_name,                       #original name
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("untyped")
                    ),
                    nnkPragma.newTree(
                        newIdentNode("dirty")
                    ),
                    newEmptyNode(),
                    nnkStmtList.newTree(
                        new_var_declaration                #new name
                    )
                )

                templates_for_constructor_var_declarations.add(constructor_var_template)
        
        #let statements
        elif statement.kind == nnkLetSection:
            for inner_index, let_declaration in statement:
                let 
                    let_declaration_name = let_declaration[0]
                    new_let_declaration = newIdentNode($(let_declaration_name.strVal()) & "_let")

                #Add the ORIGINAL ident name to the array
                let_declarations.add(let_declaration_name)

                #Then, modify the field in the code_block to be "variableName_let"
                code_block[outer_index][inner_index][0] = new_let_declaration

                #[
                    RESULT:
                    template phase() : untyped {.dirty.} =    #The untyped here is fundamental to make this act like a normal text replacement.
                        phase_let
                ]#                
                #Construct a template that replaces the "variableName" in code with "variableName_let", to be used in constructor for correct namings
                let constructor_let_template = nnkTemplateDef.newTree(
                    let_declaration_name,                       #original name
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("untyped")
                    ),
                    nnkPragma.newTree(
                        newIdentNode("dirty")
                    ),
                    newEmptyNode(),
                    nnkStmtList.newTree(
                        new_let_declaration                #new name
                    )
                )

                templates_for_constructor_let_declarations.add(constructor_let_template)
    
    #If provided a call to the "build" macro at last position:
    if new_call_provided:
        call_to_build_macro = code_block.last()

        var temp_call_to_build_macro = nnkCall.newTree()

        #[
            nnkCall is:
            build:
                a
                b

            nnkCommand is:
            build a b

            Format them both to be the same way as the normal build(a, b) nnkCall.
        ]#
        if call_to_build_macro.kind == nnkCall or call_to_build_macro.kind == nnkCommand:
            
            #nnkCommand can recursively represent elements in nnkCommand trees. Unpack all the nnkIdents and append them to the temp_call_to_build_macro variable.
            proc recursive_unpack_of_commands(input : NimNode) : void =    
                for input_children in input:
                    if input_children.kind == nnkStmtList or input_children.kind == nnkCommand:
                        recursive_unpack_of_commands(input_children)
                    else:
                        temp_call_to_build_macro.add(input_children)

            #Unpack the elements and add them to temp_call_to_build_macro, which is a nnkCall tree.
            recursive_unpack_of_commands(call_to_build_macro)
            
            #Substitute the original code block with the new one.
            call_to_build_macro = temp_call_to_build_macro
        else:
            error("'build': invalid syntax.")

        #remove the call to "build" macro from code_block. It will then be just the body of constructor function.
        code_block.del(code_block.len() - 1)
    
    #No call to "build" provided. Build one from all the var and let declarations!
    else:
        call_to_build_macro = nnkCall.newTree(
            newIdentNode("build")
        )
        
        for let_decl_ident in let_declarations:
            call_to_build_macro.add(let_decl_ident)
        
        for var_decl_ident in var_declarations:
            call_to_build_macro.add(var_decl_ident)

    #Check the variables that are passed to call_to_build_macro
    for index, build_macro_var_name in call_to_build_macro:
        #Check if any of the var_declarations are inputs to the "build" macro. If so, append their variable name with "_var"
        for var_declaration in var_declarations:
            if var_declaration == build_macro_var_name:
                #Replace the input to the "build" macro to be "variableName_var"
                let 
                    var_name_str = var_declaration.strVal()
                    new_var_declaration = newIdentNode(var_name_str & "_var")
                
                #Replace the name directly in the call to the "build" macro
                call_to_build_macro[index] = new_var_declaration

                #[
                    RESULT:
                    template phase() : untyped {.dirty.} =    #The untyped here is fundamental to make this act like a normal text replacement.
                        phase_var[]
                ]#                
                #Construct a template that replaces the "variableName" in code with "variableName_var[]", to access the field directly in the perform section.
                let perform_var_template = nnkTemplateDef.newTree(
                    var_declaration,                            #original name
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("untyped")
                    ),
                    nnkPragma.newTree(
                        newIdentNode("dirty")
                    ),
                    newEmptyNode(),
                    nnkStmtList.newTree(
                        nnkBracketExpr.newTree(
                            new_var_declaration                 #new name
                        )
                    )
                )
                
                templates_for_perform_var_declarations.add(perform_var_template)     

        #Check if any of the let_declarations are inputs to the "build" macro. If so, just append their variable name with "_let"
        for let_declaration in let_declarations:
            if let_declaration == build_macro_var_name:
                #Replace the input to the "build" macro to be "variableName_let"
                let new_let_declaration = newIdentNode(let_declaration.strVal() & "_let")

                #Replace the name directly in the call to the "build" macro
                call_to_build_macro[index] = new_let_declaration

    if templates_for_perform_var_declarations.len == 0:
        templates_for_perform_var_declarations.add(
            nnkDiscardStmt.newTree(
                newEmptyNode()
            )
        )

    #build the omni_ugen.a = a, omni_ugen.b = b constructs
    for index, var_name in call_to_build_macro:
        
        #In case user is trying to not insert a variable with name in, like "new(1)"
        if var_name.kind != nnkIdent:
            error("Trying to use a literal value at index " & $index & " of the \"new\" statement. Use a named variable instead.")
        
        #Standard case, an nnkIdent with the variable name
        if index > 0: 

            let var_name_str = var_name.strVal()

            let ugen_asgn_stmt = nnkAsgn.newTree(
                nnkDotExpr.newTree(
                    newIdentNode("omni_ugen"),
                    newIdentNode(var_name_str)  #symbol name (omni_ugen.$name)
                ),
                newIdentNode(var_name_str)      #symbol name ($name)
            )

            assign_ugen_fields.add(ugen_asgn_stmt)

            final_var_names.add(
                newIdentNode(var_name_str)
            )

            perform_build_names_table_static_stmt.add(
                nnkStmtList.newTree(
                    nnkCall.newTree(
                        nnkDotExpr.newTree(
                            newIdentNode("omni_perform_build_names_table"),
                            newIdentNode("add")
                        ),
                        newLit(var_name_str[0..(var_name_str.len)-5]) #remove _var / _let
                    )
                )
            )   

        #First ident == "build"
        else: 
            continue
    
    #Also add omni_ugen.samplerate_let = samplerate
    assign_ugen_fields.add(
        nnkAsgn.newTree(
            nnkDotExpr.newTree(
                newIdentNode("omni_ugen"),
                newIdentNode("samplerate_let")
            ),
            newIdentNode("samplerate")      
        )
    )
    
    #Prepend to the code block the declaration of the templates for name mangling, in order for the typed block in the "omni_execute_build_statement_and_create_ugen_obj" macro to correctly mangle the "_var" and "_let" named variables, before sending the result to the "build" macro
    let code_block_with_var_let_templates_and_call_to_build_macro = nnkStmtList.newTree(
        templates_for_constructor_var_declarations,
        templates_for_constructor_let_declarations,
        code_block,
        call_to_build_macro
    )

    result = quote do:
        #Template that, when called, will generate the template for the name mangling of "_var" variables in the Omni_UGenPerform proc.
        #This is a fast way of passing the `templates_for_perform_var_declarations` block of code over another section of the code, by simply evaluating the "omni_generate_templates_for_perform_var_declarations()" macro
        template omni_generate_templates_for_perform_var_declarations() : untyped {.dirty.} =
            `templates_for_perform_var_declarations`

        #These are variables declared in build, they won't be renamed in perform
        `perform_build_names_table_static`
            
        #nim >= 1.4.0 doesn't require the typed call to omni_execute_build_statement_and_create_ugen_obj
        when (NimMajor, NimMinor) < (1, 4):
            #With a macro with typed argument, I can just pass in the block of code and it is semantically evaluated. I just need then to extract the result of the "build" statement
            omni_execute_build_statement_and_create_ugen_obj(`code_block_with_var_let_templates_and_call_to_build_macro`)
        else:
            `code_block_with_var_let_templates_and_call_to_build_macro`

        #This is just allocating memory, not running constructor
        proc Omni_UGenAlloc*() : pointer {.exportc: "Omni_UGenAlloc", dynlib.} =
            #allocation of "omni_ugen" variable
            let 
                omni_ugen_ptr {.inject.} = omni_alloc(culong(sizeof(Omni_UGen)))
                omni_ugen     {.inject.} = cast[ptr Omni_UGen](omni_ugen_ptr)

            if isNil(omni_ugen_ptr):
                print("ERROR: Omni: could not allocate memory")
            
            omni_ugen.omni_auto_mem    = nil

            return omni_ugen_ptr
        
        #Define Omni_UGenFree
        proc Omni_UGenFree*(omni_ugen_ptr {.inject.} : pointer) : void {.exportc: "Omni_UGenFree", dynlib.} =
            if isNil(omni_ugen_ptr):
                print("ERROR: Omni: invalid omni_ugen_ptr to free.")
                return
            
            when defined(omni_debug):
                print("Calling Omni_UGen's destructor")
            
            let omni_ugen {.inject.} = cast[ptr Omni_UGen](omni_ugen_ptr)
            
            if not isNil(omni_ugen.omni_auto_mem):
                omni_auto_mem_free(omni_ugen.omni_auto_mem)

            omni_free(omni_ugen_ptr)

        #Generate the proc to find all datas and structs in Omni_UGen
        omni_find_structs_and_datas(Omni_UGen, true)
        
        when defined(omni_perform32):
            proc Omni_UGenInit32*(omni_ugen_ptr {.inject.} : pointer, ins_ptr {.inject.} : ptr ptr cfloat, bufsize_in {.inject.} : cint, samplerate_in {.inject.} : cdouble, buffer_interface_in {.inject.} : pointer) : int {.exportc: "Omni_UGenInit32", dynlib.} =
                if isNil(omni_ugen_ptr):
                    print("ERROR: Omni: build: invalid omni object")
                    return 0
                
                let 
                    omni_ugen        {.inject.} : ptr Omni_UGen = cast[ptr Omni_UGen](omni_ugen_ptr)     
                    omni_ins_ptr     {.inject.} : CFloatPtrPtr  = cast[CFloatPtrPtr](ins_ptr)
                    bufsize          {.inject.} : int           = int(bufsize_in)
                    samplerate       {.inject.} : float         = float(samplerate_in)
                    buffer_interface {.inject.} : pointer       = buffer_interface_in
                
                #Initialize auto_mem
                omni_ugen.omni_auto_mem    = omni_create_omni_auto_mem()

                if isNil(cast[pointer](omni_ugen.omni_auto_mem)):
                    print("ERROR: Omni: could not allocate auto_mem")
                    return 0

                let omni_auto_mem    {.inject.} : ptr Omni_AutoMem = omni_ugen.omni_auto_mem

                #Needed to be passed to all defs
                var omni_call_type   {.inject, noinit.} : typedesc[Omni_InitCall]

                #Unpack the "ins" variable names
                omni_unpack_ins_init(omni_inputs_names_const)

                #Unpack params and set default values
                omni_unpack_params_init()

                #Unpack and init buffers
                omni_unpack_buffers_init()
                omni_set_buffers_defaults()

                #Add the templates needed for Omni_UGenConstructor to unpack variable names declared with "var" (different from the one in Omni_UGenPerform, which uses unsafeAddr)
                `templates_for_constructor_var_declarations`

                #Add the templates needed for Omni_UGenConstructor to unpack variable names declared with "let"
                `templates_for_constructor_let_declarations`
                
                #Actual body of the constructor
                `code_block`

                #Assign omni_ugen fields
                `assign_ugen_fields`

                #omni_check_struct_validity triggers the checks for correct initialization of all Datas entries,
                if not omni_check_struct_validity(omni_ugen):
                    return 0
                
                return 1

            proc Omni_UGenAllocInit32*(ins_ptr {.inject.} : ptr ptr cfloat, bufsize_in {.inject.} : cint, samplerate_in {.inject.} : cdouble, buffer_interface_in {.inject.} : pointer) : pointer {.exportc: "Omni_UGenAllocInit32", dynlib.} =
                let omni_ugen_ptr {.inject.} = Omni_UGenAlloc()
                if Omni_UGenInit32(omni_ugen_ptr, ins_ptr, bufsize_in, samplerate_in, buffer_interface_in) == 1:
                    return omni_ugen_ptr
                else:
                    if not isNil(omni_ugen_ptr):
                        Omni_UGenFree(omni_ugen_ptr)
                    return cast[pointer](nil)

        when defined(omni_perform64):
            proc Omni_UGenInit64*(omni_ugen_ptr {.inject.} : pointer, ins_ptr {.inject.} : ptr ptr cdouble, bufsize_in {.inject.} : cint, samplerate_in {.inject.} : cdouble, buffer_interface_in {.inject.} : pointer) : int {.exportc: "Omni_UGenInit64", dynlib.} =
                if isNil(omni_ugen_ptr):
                    print("ERROR: Omni: build: invalid omni object")
                    return 0

                let 
                    omni_ugen        {.inject.} : ptr Omni_UGen  = cast[ptr Omni_UGen](omni_ugen_ptr)     
                    omni_ins_ptr     {.inject.} : CDoublePtrPtr  = cast[CDoublePtrPtr](ins_ptr)
                    bufsize          {.inject.} : int            = int(bufsize_in)
                    samplerate       {.inject.} : float          = float(samplerate_in)
                    buffer_interface {.inject.} : pointer        = buffer_interface_in

                #Initialize auto_mem
                omni_ugen.omni_auto_mem    = omni_create_omni_auto_mem()

                if isNil(cast[pointer](omni_ugen.omni_auto_mem)):
                    print("ERROR: Omni: could not allocate auto_mem")
                    return 0

                let omni_auto_mem    {.inject.} : ptr Omni_AutoMem = omni_ugen.omni_auto_mem

                #Needed to be passed to all defs
                var omni_call_type   {.inject, noinit.} : typedesc[Omni_InitCall]

                #Unpack the "ins" variable names
                omni_unpack_ins_init(omni_inputs_names_const)

                #Unpack params and set default values
                omni_unpack_params_init()

                #Unpack and init buffers
                omni_unpack_buffers_init()
                omni_set_buffers_defaults()

                #Add the templates needed for Omni_UGenConstructor to unpack variable names declared with "var" (different from the one in Omni_UGenPerform, which uses unsafeAddr)
                `templates_for_constructor_var_declarations`

                #Add the templates needed for Omni_UGenConstructor to unpack variable names declared with "let"
                `templates_for_constructor_let_declarations`
                
                #Actual body of the constructor
                `code_block`

                #Assign omni_ugen fields
                `assign_ugen_fields`

                #omni_check_struct_validity triggers the checks for correct initialization of all Datas entries,
                if not omni_check_struct_validity(omni_ugen):
                    return 0
                
                return 1

            proc Omni_UGenAllocInit64*(ins_ptr {.inject.} : ptr ptr cdouble, bufsize_in {.inject.} : cint, samplerate_in {.inject.} : cdouble, buffer_interface_in {.inject.} : pointer) : pointer {.exportc: "Omni_UGenAllocInit64", dynlib.} =
                let omni_ugen_ptr {.inject.} = Omni_UGenAlloc()
                if Omni_UGenInit64(omni_ugen_ptr, ins_ptr, bufsize_in, samplerate_in, buffer_interface_in) == 1:
                    return omni_ugen_ptr
                else:
                    if not isNil(omni_ugen_ptr):
                        Omni_UGenFree(omni_ugen_ptr)
                    return cast[pointer](nil)

    #error repr result

macro init*(code_block : untyped) : untyped =
    return quote do:
        #If ins / params / outs are not declared, declare them!
        when not declared(omni_declared_inputs):
            ins 1

        when not declared(omni_declared_params):
            omni_io.params 0 #not to be confused with macros' params

        when not declared(omni_declared_buffers):
            buffers 0

        when not declared(omni_declared_outputs):
            outs 1

        #Use to check variable names in perform block, to check if they are the same as declared vars from init
        var omni_perform_build_names_table {.inject, compileTime.} : seq[string]
            
        #Trick the compiler of the existence of these variables in order to parse the block.
        #These will be overwrittne in the UGenCosntructor anyway.
        let 
            bufsize            {.inject.} : int                = 0
            samplerate         {.inject.} : float              = 0.0
            buffer_interface   {.inject.} : pointer            = nil
            omni_auto_mem      {.inject.} : ptr Omni_AutoMem   = nil
        
        var omni_call_type     {.inject, noinit.} : typedesc[Omni_CallType]

        #It doesn' matter it's a CFloatPtrPtr (even for performBits:64), as it will just be replaced in the functions with the proper casting
        let omni_ins_ptr            {.inject.} : CFloatPtrPtr   = cast[CFloatPtrPtr](0)

        #Define that init exists, so perform doesn't create an empty one automatically
        #Or, if perform is defining one, define omni_declared_init here so that it will still only be defined once
        let omni_declared_init {.inject, compileTime.} = true

        #Generate fictional let names for ins (so that parser won't complain when using them)
        omni_unpack_ins_init(omni_inputs_names_const, true)

        #Generate fictional let names for params (so that parser won't complain when using them)
        omni_unpack_params_pre_init()

        #Generate fictional var names for buffers (so that parser won't complain when using them)
        #omni_unpack_buffers_pre_init()

        #Actually parse the init block
        omni_parse_block_untyped(`code_block`, true)

#Equal to init:
macro initialize*(code_block : untyped) : untyped =
    return quote do:
        init(`code_block`)

#Equal to init:
macro initialise*(code_block : untyped) : untyped =
    return quote do:
        init(`code_block`)

#This macro should in theory just work with the "build(a, b)" syntax, but for other syntaxes, the constructor macro correctly builds
#a correct call to "build(a, b)" instead of "build: \n a \n b" or "build a b" by extracting the nnkIdents from the other calls and 
#building a correct "build(a, b)" syntax out of them.
macro build*(var_names : varargs[typed]) =    
    var 
        final_type = nnkTypeSection.newTree()
        
        final_typedef = nnkTypeDef.newTree(
            nnkPragmaExpr.newTree(
                newIdentNode("Omni_UGen"),
                nnkPragma.newTree(
                    newIdentNode("inject")
                )
            ),
            newEmptyNode()
        )

        final_obj  = nnkObjectTy.newTree(
            newEmptyNode(),
            newEmptyNode()
        )
    
    final_typedef.add(final_obj)
    final_type.add(final_typedef)
    
    var var_names_and_types = nnkRecList.newTree()

    for var_name in var_names:
        let 
            var_type = var_name.getTypeImpl()
            var_type_kind = var_type.kind

        #var name is a sym, need it as ident to free it from all type infos it had
        let var_name_ident =  newIdentNode(var_name.strVal())

        var var_name_and_type = nnkIdentDefs.newTree(
           var_name_ident
        )

        #builtin or ptr (struct) type.
        if var_type_kind == nnkSym or var_type_kind == nnkIdent or var_type_kind == nnkPtrTy:
            var_name_and_type.add(
                var_type,
                newEmptyNode()
            )
        else:
            error("Omni_UGen: can't build Omni_UGen, invalid type '" & repr(var_type) & "'")

        var_names_and_types.add(
            var_name_and_type
        )

    #Add params
    for param_name in omni_params_names_list:
        var_names_and_types.add(
            nnkIdentDefs.newTree(
                newIdentNode(param_name & "_omni_param"),
                nnkBracketExpr.newTree(
                    newIdentNode("array"),
                    newLit(2),
                    newIdentNode("float")
                ),
                newEmptyNode()
            )
        )

    #Add buffers
    for buffer_name in omni_buffers_names_list:
        var_names_and_types.add(
            nnkIdentDefs.newTree(
                newIdentNode(buffer_name & "_omni_buffer"),
                newIdentNode("Buffer"),
                newEmptyNode()
            )
        )

    #Add omni_auto_mem variable (ptr Omni_AutoMem)
    var_names_and_types.add(
        nnkIdentDefs.newTree(
            newIdentNode("omni_auto_mem"),
            nnkPtrTy.newTree(
                newIdentNode("Omni_AutoMem")
            ),
            newEmptyNode()
        )
    )

    #Add omni_params_lock
    var_names_and_types.add(
        nnkIdentDefs.newTree(
            newIdentNode("omni_params_lock"),
            newIdentNode("AtomicFlag"),
            newEmptyNode()
        )
    )

    #Add omni_buffers_lock
    var_names_and_types.add(
        nnkIdentDefs.newTree(
            newIdentNode("omni_buffers_lock"),
            newIdentNode("AtomicFlag"),
            newEmptyNode()
        )
    )
    
    #Add samplerate_let variable
    var_names_and_types.add(
        nnkIdentDefs.newTree(
            newIdentNode("samplerate_let"),
            getType(float),
            newEmptyNode()
        )
    )

    #Add to final obj
    final_obj.add(var_names_and_types)

    #error repr final_obj

    return final_type