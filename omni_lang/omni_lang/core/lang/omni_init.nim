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

import macros, tables

#being the argument typed, the code_block is semantically executed after parsing, making it to return the correct result out of the "build" statement
macro executeNewStatementAndBuildUGenObjectType(code_block : typed) : untyped =   
    discard

#This has been correctly parsed!
macro init_inner*(code_block_stmt_list : untyped) =
    #Extract the actual parsed code_block from the nnkStmtList
    let code_block = code_block_stmt_list[0]

    var 
        #They both are nnkIdentNodes
        let_declarations : seq[NimNode]
        var_declarations : seq[NimNode]

        templates_for_perform_var_declarations     = nnkStmtList.newTree()
        templates_for_constructor_var_declarations = nnkStmtList.newTree()
        templates_for_constructor_let_declarations = nnkStmtList.newTree()

        call_to_build_macro : NimNode
        final_var_names = nnkBracket.newTree()
        alloc_ugen : NimNode
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

        #First element of the call_to_build_macro ([0]) is the name of the calling function (Ident("build"))
        #Second element - unpacked here - is the kind of syntax used to call the macro. It can either be just
        #a list of idents - which is the case for the normal "new(a, b)" syntax - or either a nnkStmtList - for the
        #"new : \n a \n b" syntax - or a nnkCommand list - for the "new a b" syntax.
        let type_of_syntax = call_to_build_macro[1]

        var temp_call_to_build_macro = nnkCall.newTree(newIdentNode("build"))

        #[
            nnkStmtList is:
            new:
                a
                b

            nnkCommand is:
            new a b

            Format them both to be the same way as the normal new(a, b) nnkCall.
        ]#
        if type_of_syntax.kind == nnkStmtList or type_of_syntax.kind == nnkCommand:
            
            #nnkCommand can recursively represent elements in nnkCommand trees. Unpack all the nnkIdents and append them to the temp_call_to_build_macro variable.
            proc recursive_unpack_of_commands(input : NimNode) : void =    
                for input_children in input:
                    if input_children.kind == nnkStmtList or input_children.kind == nnkCommand:
                        recursive_unpack_of_commands(input_children)
                    else:
                        temp_call_to_build_macro.add(input_children)

            #Unpack the elements and add them to temp_call_to_build_macro, which is a nnkCall tree.
            recursive_unpack_of_commands(type_of_syntax)
            
            #Substitute the original code block with the new one.
            call_to_build_macro = temp_call_to_build_macro
        else:
            error("`build`: invalid syntax.")

        #remove the call to "build" macro from code_block. It will then be just the body of constructor function.
        code_block.del(code_block.len() - 1)
    
    #No call to "build" provided. Build one from all the var and let declarations!
    else:
        call_to_build_macro = nnkCall.newTree(newIdentNode("build"))
        
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
                let new_var_declaration = newIdentNode($(var_declaration.strVal()) & "_var")
                
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
                let new_let_declaration = newIdentNode($(let_declaration.strVal()) & "_let")

                #Replace the name directly in the call to the "build" macro
                call_to_build_macro[index] = new_let_declaration

    #echo repr code_block
    #echo astGenRepr call_to_build_macro

    #echo astGenRepr templates_for_perform_var_declarations

    #First statement of the constructor is the allocation of the "ugen" variable. 
    #The allocation should be done using SC's RTAlloc functions. For testing, use alloc0 for now.
    #[
        dumpAstGen:
            var ugen: ptr UGen = cast[ptr UGen](alloc0(sizeof(UGen)))
    ]#
    alloc_ugen = nnkVarSection.newTree(
        nnkIdentDefs.newTree(
            newIdentNode("ugen"),
            nnkPtrTy.newTree(
                newIdentNode("UGen")
            ),
            nnkCast.newTree(
                nnkPtrTy.newTree(
                    newIdentNode("UGen")
                ),
                nnkCall.newTree(
                    newIdentNode("omni_alloc"),
                    nnkCall.newTree(
                        newIdentNode("culong"),
                            nnkCall.newTree(
                                newIdentNode("sizeof"),
                                newIdentNode("UGen")
                        )
                    )                 
                )
            )
        )
    )

    #build the ugen.a = a, ugen.b = b constructs
    for index, var_name in call_to_build_macro:
        
        #In case user is trying to not insert a variable with name in, like "new(1)"
        if var_name.kind != nnkIdent:
            error("Trying to use a literal value at index " & $index & " of the \"new\" statement. Use a named variable instead.")
        
        #Standard case, an nnkIdent with the variable name
        if index > 0: 

            let var_name_str = var_name.strVal()

            let ugen_asgn_stmt = nnkAsgn.newTree(
                nnkDotExpr.newTree(
                    newIdentNode("ugen"),
                    newIdentNode(var_name_str)  #symbol name (ugen.$name)
                ),
                newIdentNode(var_name_str)      #symbol name ($name)
            )

            assign_ugen_fields.add(ugen_asgn_stmt)

            final_var_names.add(newIdentNode(var_name_str))

        #First ident == "build"
        else: 
            continue
    
    #Also add ugen.samplerate_let = samplerate
    assign_ugen_fields.add(
        nnkAsgn.newTree(
            nnkDotExpr.newTree(
                newIdentNode("ugen"),
                newIdentNode("samplerate_let")
            ),
            newIdentNode("samplerate")      
        )
    )
    
    #Prepend to the code block the declaration of the templates for name mangling, in order for the typed block in the "executeNewStatementAndBuildUGenObjectType" macro to correctly mangle the "_var" and "_let" named variables, before sending the result to the "build" macro
    let code_block_with_var_let_templates_and_call_to_build_macro = nnkStmtList.newTree(
        templates_for_constructor_var_declarations,
        templates_for_constructor_let_declarations,
        code_block,
        call_to_build_macro
    )

    #echo astGenRepr call_to_build_macro
    #echo astGenRepr code_block_with_var_let_templates_and_call_to_build_macro

    result = quote do:
        #Template that, when called, will generate the template for the name mangling of "_var" variables in the Omni_UGenPerform proc.
        #This is a fast way of passing the `templates_for_perform_var_declarations` block of code over another section of the code, by simply evaluating the "generateTemplatesForPerformVarDeclarations()" macro
        template generateTemplatesForPerformVarDeclarations() : untyped {.dirty.} =
            `templates_for_perform_var_declarations`
                
        #With a macro with typed argument, I can just pass in the block of code and it is semantically evaluated. I just need then to extract the result of the "build" statement
        executeNewStatementAndBuildUGenObjectType(`code_block_with_var_let_templates_and_call_to_build_macro`)

        
        defineUGenToOmniModule(OmniCurrentModule)

        #This is just allocating memory, not running constructor
        proc Omni_UGenAlloc() : pointer {.export_Omni_UGenAlloc.} =
            #allocation of "ugen" variable
            `alloc_ugen`

            #Return ugen as void ptr
            let ugen_ptr = cast[pointer](ugen)

            if isNil(ugen_ptr):
                print("ERROR: Omni: could not allocate memory")
            
            ugen.is_initialized_let   = false
            ugen.ugen_auto_mem_let    = nil
            ugen.ugen_auto_buffer_let = nil

            return ugen_ptr
        
        #Define Omni_UGenFree
        proc Omni_UGenFree(ugen_ptr : pointer) : void {.export_Omni_UGenFree.} =
            if isNil(ugen_ptr):
                print("ERROR: Omni: invalid ugen_ptr to free.")
                return

            print("Calling UGen's destructor")
            
            let ugen = cast[ptr UGen](ugen_ptr)
            
            if not isNil(ugen.ugen_auto_mem_let):
                freeOmniAutoMem(ugen.ugen_auto_mem_let)
            
            if not isNil(ugen.ugen_auto_buffer_let):
                freeOmniAutoMem(ugen.ugen_auto_buffer_let, false)

            omni_free(ugen_ptr)

        #Generate the proc to find all datas and structs in UGen
        findDatasAndStructs(UGen, true)
        
        when defined(performBits32):
            proc Omni_UGenInit32(ugen_ptr : pointer, ins_ptr : ptr ptr cfloat, bufsize_in : cint, samplerate_in : cdouble, buffer_interface_in : pointer) : int {.export_Omni_UGenInit32.} =
                if isNil(ugen_ptr):
                    print("ERROR: Omni: build: invalid omni object")
                    return 0
                
                let 
                    ugen             {.inject.} : ptr UGen     = cast[ptr UGen](ugen_ptr)     
                    ins_Nim          {.inject.} : CFloatPtrPtr = cast[CFloatPtrPtr](ins_ptr)
                    bufsize          {.inject.} : int          = int(bufsize_in)
                    samplerate       {.inject.} : float        = float(samplerate_in)
                    buffer_interface {.inject.} : pointer      = buffer_interface_in
                
                #Initialize auto_mem
                ugen.ugen_auto_mem_let    = allocInitOmniAutoMem()
                ugen.ugen_auto_buffer_let = allocInitOmniAutoMem()

                if isNil(cast[pointer](ugen.ugen_auto_mem_let)):
                    print("ERROR: Omni: could not allocate auto_mem")
                    return 0

                if isNil(cast[pointer](ugen.ugen_auto_buffer_let)):
                    print("ERROR: Omni: could not allocate auto_buffer")
                    return 0

                let 
                    ugen_auto_mem    {.inject.} : ptr OmniAutoMem = ugen.ugen_auto_mem_let
                    ugen_auto_buffer {.inject.} : ptr OmniAutoMem = ugen.ugen_auto_buffer_let

                #Needed to be passed to all defs
                var ugen_call_type   {.inject, noinit.} : typedesc[InitCall]

                #Add the templates needed for Omni_UGenConstructor to unpack variable names declared with "var" (different from the one in Omni_UGenPerform, which uses unsafeAddr)
                `templates_for_constructor_var_declarations`

                #Add the templates needed for Omni_UGenConstructor to unpack variable names declared with "let"
                `templates_for_constructor_let_declarations`
                
                #Actual body of the constructor
                `code_block`

                #Assign ugen fields
                `assign_ugen_fields`

                if not checkValidity(ugen, ugen_auto_buffer):
                    ugen.is_initialized_let = false
                    return 0

                #Successful init
                ugen.is_initialized_let = true
                
                return 1

            proc Omni_UGenAllocInit32(ins_ptr : ptr ptr cfloat, bufsize_in : cint, samplerate_in : cdouble, buffer_interface_in : pointer) : pointer {.export_Omni_UGenAllocInit32.} =
                let ugen_ptr = Omni_UGenAlloc()
                if Omni_UGenInit32(ugen_ptr, ins_ptr, bufsize_in, samplerate_in, buffer_interface_in) == 1:
                    return ugen_ptr
                else:
                    if not isNil(ugen_ptr):
                        Omni_UGenFree(ugen_ptr)
                    return cast[pointer](nil)

        when defined(performBits64):
            proc Omni_UGenInit64(ugen_ptr : pointer, ins_ptr : ptr ptr cdouble, bufsize_in : cint, samplerate_in : cdouble, buffer_interface_in : pointer) : int {.export_Omni_UGenInit64.} =
                if isNil(ugen_ptr):
                    print("ERROR: Omni: build: invalid omni object")
                    return 0

                let 
                    ugen             {.inject.} : ptr UGen      = cast[ptr UGen](ugen_ptr)     
                    ins_Nim          {.inject.} : CDoublePtrPtr = cast[CDoublePtrPtr](ins_ptr)
                    bufsize          {.inject.} : int           = int(bufsize_in)
                    samplerate       {.inject.} : float         = float(samplerate_in)
                    buffer_interface {.inject.} : pointer       = buffer_interface_in

                #Initialize auto_mem
                ugen.ugen_auto_mem_let    = allocInitOmniAutoMem()
                ugen.ugen_auto_buffer_let = allocInitOmniAutoMem()

                if isNil(cast[pointer](ugen.ugen_auto_mem_let)):
                    print("ERROR: Omni: could not allocate auto_mem")
                    return 0
                
                if isNil(cast[pointer](ugen.ugen_auto_buffer_let)):
                    print("ERROR: Omni: could not allocate auto_buffer")
                    return 0

                let 
                    ugen_auto_mem    {.inject.} : ptr OmniAutoMem = ugen.ugen_auto_mem_let
                    ugen_auto_buffer {.inject.} : ptr OmniAutoMem = ugen.ugen_auto_buffer_let

                #Needed to be passed to all defs
                var ugen_call_type   {.inject, noinit.} : typedesc[InitCall]
        
                #Add the templates needed for Omni_UGenConstructor to unpack variable names declared with "var" (different from the one in Omni_UGenPerform, which uses unsafeAddr)
                `templates_for_constructor_var_declarations`

                #Add the templates needed for Omni_UGenConstructor to unpack variable names declared with "let"
                `templates_for_constructor_let_declarations`
                
                #Actual body of the constructor
                `code_block`

                #Assign ugen fields
                `assign_ugen_fields`

                if not checkValidity(ugen, ugen_auto_buffer):
                    ugen.is_initialized_let = false
                    return 0
                    
                #Successful init
                ugen.is_initialized_let = true

                return 1

            proc Omni_UGenAllocInit64(ins_ptr : ptr ptr cdouble, bufsize_in : cint, samplerate_in : cdouble, buffer_interface_in : pointer) : pointer {.export_Omni_UGenAllocInit64.} =
                let ugen_ptr = Omni_UGenAlloc()
                if Omni_UGenInit64(ugen_ptr, ins_ptr, bufsize_in, samplerate_in, buffer_interface_in) == 1:
                    return ugen_ptr
                else:
                    if not isNil(ugen_ptr):
                        Omni_UGenFree(ugen_ptr)
                    return cast[pointer](nil)
                
macro init*(code_block : untyped) : untyped =
    return quote do:
        #If ins / outs are not declared, declare them!
        when not declared(declared_inputs):
            ins 1

        when not declared(declared_outputs):
            outs 1
            
        #Trick the compiler of the existence of these variables in order to parse the block.
        #These will be overwrittne in the UGenCosntructor anyway.
        let 
            bufsize          {.inject.} : int                = 0
            samplerate       {.inject.} : float              = 0.0
            buffer_interface {.inject.} : pointer            = nil
            ugen_auto_mem    {.inject.} : ptr OmniAutoMem    = nil
            ugen_auto_buffer {.inject.} : ptr OmniAutoMem    = nil
        
        var ugen_call_type   {.inject, noinit.} : typedesc[CallType]

        #It doesn' matter it's a CFloatPtrPtr (even for performBits:64), as it will just be replaced in the functions with the proper casting
        let ins_Nim          {.inject.} : CFloatPtrPtr   = cast[CFloatPtrPtr](0)

        #Define that init exists, so perform doesn't create an empty one automatically
        #Or, if perform is defining one, define init_block here so that it will still only be defined once
        let init_block {.inject, compileTime.} = true

        parse_block_for_variables(`code_block`, true)

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
                newIdentNode("UGen"),
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
        let var_type = var_name.getTypeImpl()

        var var_name_and_type = nnkIdentDefs.newTree()
        var_name_and_type.add(newIdentNode(var_name.strVal()))

        #object type
        if var_type.kind == nnkObjectTy:
            let fully_parametrized_object = var_name.getImpl()[2][0] #Extract the BracketExpr that represents the "MyObject[T, Y, ...]" syntax from the type.
            
            var_name_and_type.add(fully_parametrized_object)

        #ref object type. Don't support them as of now.
        #This should work just fine... Don't support it for now.
        elif var_type.kind == nnkRefTy:
            error("\"" & $var_name & "\"" & " is a ref object. ref objects are not supported.")
        
        #builtin type, expressed here as a nnkSym
        else:
            var_name_and_type.add(var_type)

        var_name_and_type.add(newEmptyNode())
        var_names_and_types.add(var_name_and_type)

    #Add ugen_auto_mem_let variable (ptr OmniAutoMem)
    var_names_and_types.add(
        nnkIdentDefs.newTree(
            newIdentNode("ugen_auto_mem_let"),
            nnkPtrTy.newTree(
                newIdentNode("OmniAutoMem")
            ),
            newEmptyNode()
        )
    )

    #Add ugen_auto_buffer_let variable (ptr OmniAutoMem)
    var_names_and_types.add(
        nnkIdentDefs.newTree(
            newIdentNode("ugen_auto_buffer_let"),
            nnkPtrTy.newTree(
                newIdentNode("OmniAutoMem")
            ),
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

    #Add is_initialized_let variable
    var_names_and_types.add(
        nnkIdentDefs.newTree(
            newIdentNode("is_initialized_let"),
            getType(bool),
            newEmptyNode()
        )
    )

    #Add to final obj
    final_obj.add(var_names_and_types)

    return final_type