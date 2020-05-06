import os, strutils, macros

template defineOmniModule*() : untyped =
    let declared_module {.inject, compileTime.} : bool = true
    
    const 
        OmniTopLevelModule {.strdefine, inject.} : string = ""  #defined on command line with -d:OmniTopLevelModule=...
        OmniCurrentModule  {.inject.}            : string = (splitFile(instantiationInfo(0)[0])).name #0 arg to instantiationInfo to tell it not to go up the stack.

    #Define the export pragmas IF current module is top module (a.k.a, the compiled omni file)
    when OmniTopLevelModule == OmniCurrentModule:
        {.pragma: export_Omni_UGenInputs, exportc: "Omni_UGenInputs", dynlib.}
        {.pragma: export_Omni_UGenInputNames, exportc:"Omni_UGenInputNames", dynlib.}
        {.pragma: export_Omni_UGenDefaults, exportc: "Omni_UGenDefaults", dynlib.}
        {.pragma: export_Omni_UGenOutputs, exportc: "Omni_UGenOutputs", dynlib.}
        {.pragma: export_Omni_UGenOutputNames, exportc:"Omni_UGenOutputNames", dynlib.}
        {.pragma: export_Omni_UGenAlloc, exportc: "Omni_UGenAlloc", dynlib.}
        {.pragma: export_Omni_UGenFree,  exportc: "Omni_UGenFree", dynlib.}
        {.pragma: export_Omni_UGenInit32,  exportc: "Omni_UGenInit32", dynlib.}
        {.pragma: export_Omni_UGenAllocInit32,  exportc: "Omni_UGenAllocInit32", dynlib.}
        {.pragma: export_Omni_UGenInit64,  exportc: "Omni_UGenInit64", dynlib.}
        {.pragma: export_Omni_UGenAllocInit64,  exportc: "Omni_UGenAllocInit64", dynlib.}
        {.pragma: export_Omni_UGenPerform32,  exportc: "Omni_UGenPerform32", dynlib.}
        {.pragma: export_Omni_UGenPerform64,  exportc: "Omni_UGenPerform64", dynlib.}
    
    #When module is not top module, don't export to dylib!
    else:
        {.pragma: export_Omni_UGenInputs.}
        {.pragma: export_Omni_UGenInputNames.}
        {.pragma: export_Omni_UGenDefaults.}
        {.pragma: export_Omni_UGenOutputs.}
        {.pragma: export_Omni_UGenOutputNames.}
        {.pragma: export_Omni_UGenAlloc.}
        {.pragma: export_Omni_UGenFree.}
        {.pragma: export_Omni_UGenInit32.}
        {.pragma: export_Omni_UGenAllocInit32.}
        {.pragma: export_Omni_UGenInit64.}
        {.pragma: export_Omni_UGenAllocInit64.}
        {.pragma: export_Omni_UGenPerform32.}
        {.pragma: export_Omni_UGenPerform64.}

#module_name as untyped so it's identNode, not symNode. num_inputs/outputs will be nnkLit
proc generate_omni_module_init_functions*(module_name : NimNode, code_block : NimNode, #[assign_ugen_fields : NimNode,]# num_inputs : NimNode, input_names : NimNode, default_values : NimNode, num_outputs : NimNode) : NimNode =
    result = nnkStmtList.newTree()

    let 
        num_inputs_int     = num_inputs.intVal()
        input_names_str    = input_names.getImpl().strVal()
        default_values_arr = default_values.getImpl()

    var 
        init_proc_def = nnkProcDef.newTree(
            newIdentNode("module_init_inner"),
            newEmptyNode(),
            newEmptyNode()
        )

        init_formal_params = nnkFormalParams.newTree(
            module_name,
            nnkIdentDefs.newTree(
                newIdentNode("module"),
                nnkBracketExpr.newTree(
                    newIdentNode("typedesc"),
                    module_name
                ),
                newEmptyNode()
            )
        )

        init_template_def = nnkTemplateDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("init")
            ),
            newEmptyNode(),
            newEmptyNode()
        )

        init_template_call = nnkCall.newTree(
            newIdentNode("module_init_inner"),
            module_name
        )

        init_proc_body = nnkStmtList.newTree()
        init_arg_templates = nnkStmtList.newTree()

    #Set arg as name for init
    for i in 0..num_inputs_int-1:
        let 
            arg_name = newIdentNode("arg" & $(i+1))
            in_name  = newIdentNode("in" & $(i+1))
        
        let ident_def = nnkIdentDefs.newTree(
            arg_name,
            newIdentNode("float"),
            newLit(0.0)
        )
        
        init_formal_params.add(ident_def)

        init_template_call.add(arg_name)

        let template_def = nnkTemplateDef.newTree(
            in_name,
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
                arg_name
            )
        )

        init_arg_templates.add(template_def)

    #Other arguments to the template call
    init_template_call.add(
        newIdentNode("samplerate"),
        newIdentNode("bufsize"),
        newIdentNode("buffer_interface"),
        newIdentNode("ugen_auto_mem"),
        newIdentNode("ugen_auto_buffer")
    )

    #Add to template_def before adding more stuff to init_arg_templates
    init_template_def.add(
        init_formal_params.copy(),
        newEmptyNode(),
        newEmptyNode(),
        nnkStmtList.newTree(
            init_template_call
        )
    )

    #add last two args, ugen_auto_mem and ugen_auto_buffer
    init_formal_params.add(
        nnkIdentDefs.newTree(
            newIdentNode("samplerate"),
            newIdentNode("float"),
            newEmptyNode()
        ),

        nnkIdentDefs.newTree(
            newIdentNode("bufsize"),
            newIdentNode("int"),
            newEmptyNode()
        ),

        nnkIdentDefs.newTree(
            newIdentNode("buffer_interface"),
            newIdentNode("pointer"),
            newEmptyNode()
        ),

        nnkIdentDefs.newTree(
            newIdentNode("ugen_auto_mem"),
            nnkPtrTy.newTree(
                newIdentNode("OmniAutoMem")
            ),
            newEmptyNode()
        ),

        nnkIdentDefs.newTree(
            newIdentNode("ugen_auto_buffer"),
            nnkPtrTy.newTree(
                newIdentNode("OmniAutoMem")
            ),
            newEmptyNode()
        )
    )
    
    #Add the in templates
    init_proc_body.add(
        init_arg_templates
    )

    #ptr UGen is here the one in the current module, it equlas to module_name
    init_proc_body.add(
        parseStmt("""
let 
    ugen_ptr = Omni_UGenAlloc()
    ugen = cast[ptr UGen](ugen_ptr)
if isNil(ugen_ptr):
    return ugen
ugen.ugen_auto_mem_let    = ugen_auto_mem
ugen.ugen_auto_buffer_let = ugen_auto_buffer

var ugen_call_type   {.noinit.} : typedesc[InitCall]
""")
    )

    #Add code_block and assign_ugen_fields
    init_proc_body.add(
        code_block,
        #assign_ugen_fields,
        nnkReturnStmt.newTree(
            newIdentNode("ugen")
        )
    )

    #Add args and body to proc definition
    init_proc_def.add(
        init_formal_params,
        newEmptyNode(),
        newEmptyNode(),
        init_proc_body
    )

    result.add(init_proc_def)
    result.add(init_template_def)

    #echo repr result
    
#This actually define the exportable module
macro defineOmniModuleInit*(name : typed, code_block : untyped, num_inputs : typed, input_names : typed, default_values : typed, num_outputs : typed) : untyped =
    let name_kind = name.kind
    
    if name_kind != nnkIdent and name_kind != nnkSym:
        error("Invalid omni module name")

    #This is the actual name of the module
    let 
        module_name = newIdentNode(name.getImpl.strVal)
        module_init = generate_omni_module_init_functions(module_name, code_block,num_inputs, input_names, default_values, num_outputs)

    echo repr module_init

    return quote do:
        type
            `module_name`* = ptr UGen

        #Generate init function for the module
        #`module_init`

macro defineOmniModulePerform*(name : typed, code_block : untyped) : untyped =
    discard
    #This can also return tuple of floats
    #proc perform*(obj : typedesc[`name_lit`], in1 : float, in2 : float) : float =