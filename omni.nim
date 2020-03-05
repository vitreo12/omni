import cligen, terminal, os, strutils, osproc

#omni version
const omni_ver = "0.1.0"

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
    writeStyled(msg)

#Generic success proc
proc printDone(msg : string) : void =
    setForegroundColor(fgGreen)
    writeStyled("DONE: ", {styleBright}) 
    setForegroundColor(fgWhite, true)
    writeStyled(msg)

#Actual compiler
proc omni(file : string, architecture : string = "native", lib : string = "shared", outDir : string = "", define : seq[string] = @[],  importModule  : seq[string] = @[]) : void =

    let 
        fileFullPath      = absolutePath(file)
        fileFullPathShell = fileFullPath.replace(" ", "\\ ")

    #Check if file exists
    if not fileFullPath.existsFile():
        printError($fileFullPath & " doesn't exist.")
        return

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
        return
    
    var outDirFullPath : string

    #Check if outDir is empty. Use .omni's file path in that case.
    if outDir == "":
        outDirFullPath = omniFileDir
    else:
        outDirFullPath = outDir.absolutePath()
    
    #Check if dir exists
    if not outDirFullPath.existsDir():
        printError($outDirFullPath & " doesn't exist.")
        return

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
        return
    
    #Create a directory for result and cd into it: cd into it is needed by nim compiler to do --app:staticLib due to this bug: https://github.com/nim-lang/Omni/issues/12745
    #removeDir(fullPathToNewFolder)
    #createDir(fullPathToNewFolder)
    setCurrentDir(outDirFullPath)
    
    #Actual compile command
    #If using omni_lang as name for nimble package, --import:omni_lang is enough.
    var compile_command = "nim c --import:omni-" & omni_ver & "/omnipkg/core/omni_lang --app:" & $lib_nim & " --out:lib" & $omniFileName & $lib_extension & " --gc:none --noMain --hints:off --warning[UnusedImport]:off --deadCodeElim:on --checks:off --assertions:off --opt:speed --passC:-fPIC --passC:-march=" & $architecture & " -d:release -d:danger"
    

    #Append additional definitions
    for new_define in define:
        compile_command.add(" -d:" & $new_define)
    
    # -d:supercollider -d:supernova -d:multithread_buffers -d:writeIO -d:tempDir=" & $fullPathToNewFolderShell & " 

    #Append additional imports
    for new_importModule in importModule:
        compile_command.add(" --import:" & $new_importModule)

    #Finally, append the path to the actual omni file to compile:
    compile_command.add(" " & $fileFullPathShell)

    echo compile_command
    
    #Actually execute compilation
    let failedOmniCompilation = execCmd(compile_command)

    #error code from execCmd is usually some 8bit number saying what error arises. I don't care which one for now.
    if failedOmniCompilation > 0:
        printError("Unsuccessful compilation of " & $omniFileName & $omniFileExt)
        return

    printDone("Successful compilation of " & fileFullPath & " to folder " & $outDirFullPath)

#Unpack files arg and pass it to compiler
proc omni_cli(files : seq[string], architecture : string = "native", lib : string = "shared", outDir : string = "", define : seq[string] = @[], importModule  : seq[string] = @[]) : void =
    for file in files:
        omni(file, architecture, lib, outDir, define, importModule)

#Dispatch the omni function as the CLI one
dispatch(omni_cli, 

    help={ "architecture" : "Build architecture.",
           "lib" : "Build a shared or static library",
           "outDir" : "Output folder",
           "define" : "Define symbols for compiler",
           "importModule" : "Import nim modules into the project"
    }

)