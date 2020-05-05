from os import splitFile

template defineCurrentModule*() : untyped =
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