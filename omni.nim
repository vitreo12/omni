import cligen, terminal, os, strutils, osproc

#Package version is passed as argument when building. It will be constant and set correctly
const 
    NimblePkgVersion {.strdefine.} = ""
    omni_ver = NimblePkgVersion

#Extension for static lib
const static_lib_extension = ".a"

#Extensions for shared lib
when defined(Linux):
    const shared_lib_extension = ".so"

when defined(MacOSX) or defined(MacOS):
    const shared_lib_extension = ".dylib"

when defined(Windows):
    const shared_lib_extension = ".dll"

#Generic error proc
proc printError(msg : string) : void =
    setForegroundColor(fgRed)
    writeStyled("ERROR: ", {styleBright}) 
    setForegroundColor(fgWhite, true)
    writeStyled(msg & "\n")

#Generic success proc
proc printDone(msg : string) : void =
    setForegroundColor(fgGreen)
    writeStyled("DONE: ", {styleBright}) 
    setForegroundColor(fgWhite, true)
    writeStyled(msg & "\n")

#Actual compiler
proc omni(file : string, outName : string = "", outDir : string = "", lib : string = "shared", architecture : string = "native",  define : seq[string] = @[], importModule  : seq[string] = @[]) : int =

    let fileFullPath = file.normalizedPath().expandTilde().absolutePath()

    #Check if file exists
    if not fileFullPath.existsFile():
        printError($fileFullPath & " doesn't exist.")
        return 1

    var 
        omniFile     = splitFile(fileFullPath)
        omniFileDir  = omniFile.dir
        omniFileName = omniFile.name
        omniFileExt  = omniFile.ext

    #Check file first charcter, must be a capital letter
    if not omniFileName[0].isUpperAscii:
        omniFileName[0] = omniFileName[0].toUpperAscii()

    #Check file extension
    if not(omniFileExt == ".omni") and not(omniFileExt == ".oi"):
        printError($fileFullPath & " is not an omni file.")
        return 1
    
    var outDirFullPath : string

    #Check if outDir is empty. Use .omni's file path in that case.
    if outDir == "":
        outDirFullPath = omniFileDir
    else:
        outDirFullPath = outDir.normalizedPath().expandTilde().absolutePath()
    
    #Check if dir exists
    if not outDirFullPath.existsDir():
        printError($outDirFullPath & " doesn't exist.")
        return 1

    #This is the path to the original omni file to be used in shell.
    #Using this one in omni command so that errors are shown on this one when CTRL+Click on terminal
    #let fullPathToNewFolder = $outDirFullPath & "/" & $omniFileName

    #Check lib argument
    var 
        lib_nim : string
        lib_extension : string
    
    if lib == "shared":
        lib_nim = "lib"
        lib_extension = shared_lib_extension
    elif lib == "static":
        lib_nim = "staticLib"
        lib_extension = static_lib_extension
    else:
        printError("Invalid -lib argument: \"" & $lib & "\". Use \"shared\" to build a shared library, or \"static\" to build a static one.")
        return 1

    #Set output name:
    var output_name : string
    if outName == "":
        output_name = "lib" & $omniFileName & $lib_extension
    else:
        output_name = $outName & $lib_extension
    
    #CD into out dir. This is needed by nim compiler to do --app:staticLib due to this bug: https://github.com/nim-lang/Omni/issues/12745
    setCurrentDir(outDirFullPath)
    
    #Actual compile command
    var compile_command = "nim c --app:" & $lib_nim & " --out:" & $output_name & " --gc:none --noMain --hints:off --warning[UnusedImport]:off --deadCodeElim:on --checks:off --assertions:off --opt:speed --passC:-fPIC --passC:-march=" & $architecture & " -d:release -d:danger"
    
    #Append additional definitions
    for new_define in define:

        #Look if -d has paths in it. Paths are expressed like so: -d:tempDir:"./"
        let split_define = new_define.split(':')
        
        #Standard case -d:danger
        if split_define.len() <= 1:
            compile_command.add(" -d:" & $new_define)
        
        #Normal and unix paths
        elif split_define.len() == 2:
            let 
                define_type  = split_define[0]
                define_path  = split_define[1]

            if define_path.contains('/') or define_path.contains('\\'):
                compile_command.add(" -d:" & $define_type & ":\"" & $define_path & "\"")

        #Windows has C:\\
        elif split_define.len() == 3:
            let define_type  = split_define[0]
            var define_path  = split_define[1]
            
            #Add the full path back
            define_path.add(":" & $(split_define[2]))

            if define_path.contains('/') or define_path.contains('\\'):
                compile_command.add(" -d:" & $define_type & ":\"" & $define_path & "\"")

    #Append additional imports. If any of these end with "_lang", don't import "omni_lang", as it means that there is a wrapper going on ("omnicollider_lang", "omnimax_lang", etc...)
    var import_omni_lang = true
    for new_importModule in importModule:
        if new_importModule.endsWith("_lang"):
            import_omni_lang = false
        compile_command.add(" --import:" & $new_importModule)

    if import_omni_lang:
        compile_command.add(" --import:omni_lang")

    #Finally, append the path to the actual omni file to compile:
    compile_command.add(" \"" & $fileFullPath & "\"")

    echo compile_command
    
    #Actually execute compilation
    when not defined(Windows):
        let failedOmniCompilation = execCmd(compile_command)
    else:
        let failedOmniCompilation = execShellCmd(compile_command)

    #error code from execCmd is usually some 8bit number saying what error arises. I don't care which one for now.
    if failedOmniCompilation > 0:
        printError("Unsuccessful omni compilation of " & $omniFileName & $omniFileExt & ".")
        return 1

    printDone("Successful compilation of \"" & fileFullPath & "\" to folder \"" & $outDirFullPath & "\".")

    return 0

#Unpack files arg and pass it to compiler
proc omni_cli(files : seq[string], outName : string = "", outDir : string = "", lib : string = "shared", architecture : string = "native",  define : seq[string] = @[], importModule  : seq[string] = @[]) : int =
    
    #echo "files"
    #echo files

    #Single file, pass the outName
    if files.len == 1:
        return omni(files[0], outName, outDir, lib, architecture, define, importModule)
    else:
        for file in files:
            if omni(file, "", outDir, lib, architecture, define, importModule) > 0:
                return 1
        return 0

#Dispatch the omni function as the CLI one
dispatch(omni_cli, 
    short={"outName" : 'n'},
    
    help={ 
            "outName" : "Name for the output, defaults to \"lib{omnifile}\".",
            "outDir" : "Output folder.",
            "lib" : "Build a shared or static library.",
            "architecture" : "Build architecture.",
            "define" : "Define symbols for the compiler.",
            "importModule" : "Import nim modules to be compiled with the omni project."
    }

)