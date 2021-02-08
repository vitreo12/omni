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

import cligen, terminal, os, strutils, osproc

#Package version is passed as argument when building. It will be constant and set correctly
const 
    NimblePkgVersion {.strdefine.} = ""
    omni_ver = NimblePkgVersion

#-v / --version
let version_flag = "Omni - version " & $omni_ver & "\n(c) 2020 Francesco Cameli"

#Path to omni_lang
const omni_lang_pkg_path = "~/.nimble/pkgs/omni_lang-" & omni_ver & "/omni_lang"

#Extension for static lib
when defined(Linux):
    const 
        lib_prepend          = "lib"
        static_lib_extension = ".a"
        shared_lib_extension = ".so"
        default_compiler     = "gcc"

when defined(MacOSX) or defined(MacOS):
    const 
        lib_prepend          = "lib"
        static_lib_extension = ".a"
        shared_lib_extension = ".dylib"
        default_compiler     = "clang"

when defined(Windows):
    const 
        lib_prepend          = ""           #Windows doesn't prepend "lib" to libraries
        static_lib_extension = ".lib"
        shared_lib_extension = ".dll"
        default_compiler     = "gcc(MinGW)"

#Generic error proc
proc printError(msg : string) : void =
    setForegroundColor(fgRed)
    writeStyled("ERROR [omni]: ", {styleBright}) 
    setForegroundColor(fgWhite, true)
    writeStyled(msg & "\n")

#Generic success proc
proc printDone(msg : string) : void =
    setForegroundColor(fgGreen)
    writeStyled("DONE [omni]: ", {styleBright}) 
    setForegroundColor(fgWhite, true)
    writeStyled(msg & "\n")

#parse compilation output for Gc allocations and pretty print it with colors
proc parseAndPrintCompilationString(msg : string) : bool =
    #Turn Error: and Warning: into red bright(1m) Error: (ansi escape codes: https://forum.nim-lang.org/t/7002)
    var colored_msg = msg.multiReplace([("Error:", "\e[31;1mError:\e[0m"), ("Warning:", "\e[31;1mError:\e[0m")])
    echo colored_msg

    #Check GcMem. --warningAsError doesn't work correctly, as it would print error even when there is not!
    if msg.contains("GcMem"):
        printError("Trying to allocate memory through Nim's Garbage Collector. This is not allowed in Omni. Use 'Data' for all your allocations.")
        return true

    return false

#Actual compiler
proc omni_single_file(fileFullPath : string, outName : string = "", outDir : string = "", lib : string = "shared", architecture : string = "native",  compiler : string = default_compiler, performBits : string = "32/64", wrapper : string = "", define : seq[string] = @[], importModule  : seq[string] = @[], exportHeader : bool = true, exportIO : bool = false) : int =

    var 
        omniFile     = splitFile(fileFullPath)
        omniFileDir  = omniFile.dir
        omniFileName = omniFile.name
        omniFileExt  = omniFile.ext
    
    let originalOmniFileName = omniFileName

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
    if not outDirFullPath.dirExists():
        printError("outDir: " & $outDirFullPath & " does not exist.")
        return 1

    #Check performBits argument
    if performBits != "32" and performBits != "64" and performBits != "32/64":
        printError("performBits: " & $performBits & " is invalid. Only valid valiues are \"32\", \"64\" and \"32/64\".")
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
        printError("Invalid --lib argument: \"" & $lib & "\". Use 'shared' to build a shared library, or 'static' to build a static one.")
        return 1

    #Set output name:
    var output_name : string
    if outName == "":
        output_name = $lib_prepend & $omniFileName & $lib_extension
    else:
        output_name = $lib_prepend & $outName & $lib_extension
    
    #CD into out dir. This is needed by nim compiler to do --app:staticLib due to this bug: https://github.com/nim-lang/Nim/issues/12745
    setCurrentDir(outDirFullPath)

    #If architecture == native, also pass the mtune=native flag.
    #If architecture == none, no architecture applied
    var real_architecture = "--passC:-march=" & $architecture
    if architecture == "native":
        real_architecture = real_architecture & " --passC:-mtune=native"
    #x86_64 / amd64 as aliases for x86-64
    elif architecture == "x86_64" or architecture == "amd64":
        real_architecture = "--passC:-march=x86-64"
    elif architecture == "none":
        real_architecture = ""

    #Add -d:lto only on Linux and Windows (not working on OSX + Clang yet: https://github.com/nim-lang/Nim/issues/15578)
    var lto = ""
    when defined(Linux) or defined(Windows):
        lto = "-d:lto"
    
    #Actual compile command. Keep the --forceBuild:on in order to recompile omni modules when changing them!
    var compile_command = "nim c --app:" & $lib_nim & " --out:" & $output_name & " -d:release -d:danger " & lto & " --opt:speed --gc:none --forceBuild:on --noMain:on --hints:off --warning[UnusedImport]:off --deadCodeElim:on --colors:off --stdout:on --checks:off --assertions:off --panics:on --passC:-fPIC " & $real_architecture

    #Fix for -d:lto not working yet on OSX + Clang: https://github.com/nim-lang/Nim/issues/15578
    when defined(MacOSX) or defined(MacOS):
        compile_command.add(" --passC:-\"flto\" --passL:-\"flto\"")

    #Add compiler info if not default compiler (which is passed in already from nim.cfg)
    if compiler != default_compiler:
        compile_command.add(" --cc:" & compiler)

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

    #Set performBits flag
    if performBits == "32":
        compile_command.add(" -d:omni_perform32")
    elif performBits == "64":
        compile_command.add(" -d:omni_perform64")
    else:
        compile_command.add(" -d:omni_perform32 -d:omni_perform64")

    #Import omni_lang first
    compile_command.add(" --import:omni_lang")
    
    #Check if a wrapper has been specified. If it is, import it
    if wrapper.isEmptyOrWhitespace.not:
        compile_command.add(" --import:\"" & wrapper & "\"")
    
    #Append additional imports
    for new_importModule in importModule:
        compile_command.add(" --import:\"" & $new_importModule & "\"")

    #Export IO
    if exportIO:
        compile_command.add(" -d:omni_export_io -d:tempDir:\"" & $outDirFullPath & "\"")

    #Finally, append the path to the actual omni file to compile:
    compile_command.add(" \"" & $fileFullPath & "\"")

    #Actually execute compilation. execCmdEx works fine on all OSes
    let (compilationString, failedOmniCompilation) = execCmdEx(compile_command)

    #Check for GcMem warnings and print out 
    let failedParsingOmniCompilationString = parseAndPrintCompilationString(compilationString)

    if failedParsingOmniCompilationString:
        return 1

    #error code from execCmd is usually some 8bit number saying what error arises. I don't care which one for now.
    if failedOmniCompilation > 0:
        printError("Unsuccessful compilation of " & $originalOmniFileName & $omniFileExt & ".")
        return 1
    
    let pathToCompiledLib = outDirFullPath & "/" & $output_name
    
    #Check if Omni_UGenPerform32/64 are present, meaning perform/sample has been correctly specified. nm works with both shared and static libs!
    when not defined(Windows):
        let failedOmniCheckPerform = execCmd("nm \"" & $pathToCompiledLib & "\" | grep -q -F Omni_UGenPerform")            # -q == silent output
    else:
        let failedOmniCheckPerform = execShellCmd("nm \"" & $pathToCompiledLib & "\" | findstr Omni_UGenPerform >$null")   # >$null == silent output
        if fileExists("$null"):
            removeFile("$null")

    #grep/findstr return 0 if it finds the string, 1 if it doesnt!
    if failedOmniCheckPerform > 0:
        printError("Undefined 'perform' or 'sample' blocks.")
        removeFile(pathToCompiledLib)
        return 1

    #Export omni.h too
    if exportHeader:
        let 
            omni_header_path     = (omni_lang_pkg_path & "/core/omni.h").normalizedPath().expandTilde().absolutePath()
            omni_header_out_path = outDirFullPath & "/omni.h"
        
        if not omni_header_path.fileExists():
            printError("exportHeader: " & $omni_header_path & " does not exist.")
            return 1
        
        copyFile(omni_header_path, omni_header_out_path)

    printDone("Successful compilation of \"" & fileFullPath & "\" to folder \"" & $outDirFullPath & "\".")

    return 0

#Unpack files arg and pass it to compiler
proc omni(files : seq[string], outName : string = "", outDir : string = "", lib : string = "shared", architecture : string = "native", compiler : string = default_compiler, performBits : string = "32/64", wrapper : string = "", define : seq[string] = @[], importModule  : seq[string] = @[], exportHeader : bool = true, exportIO : bool = false) : int =
    #no files provided, print --version
    if files.len == 0:
        echo version_flag
        return 0

    for omniFile in files:
        #Get full extended path
        let omniFileFullPath = omniFile.normalizedPath().expandTilde().absolutePath()

        #If it's a file, compile it
        if omniFileFullPath.fileExists():
            #if just one file in CLI, also pass the outName flag
            if files.len == 1:
                return omni_single_file(omniFileFullPath, outName, outDir, lib, architecture, compiler, performBits, wrapper, define, importModule, exportHeader, exportIO)
            else:
                if omni_single_file(omniFileFullPath, "", outDir, lib, architecture, compiler, performBits, wrapper, define, importModule, exportHeader, exportIO) > 0:
                    return 1

        #If it's a dir, compile all .omni/.oi files in it
        elif omniFileFullPath.dirExists():
            for kind, dirFile in walkDir(omniFileFullPath):
                if kind == pcFile:
                    let 
                        dirFileFullPath = dirFile.normalizedPath().expandTilde().absolutePath()
                        dirFileExt = dirFileFullPath.splitFile().ext
                    
                    if dirFileExt == ".omni" or dirFileExt == ".oi":
                        if omni_single_file(dirFileFullPath, "", outDir, lib, architecture, compiler, performBits, wrapper, define, importModule, exportHeader, exportIO) > 0:
                            return 1

        else:
            printError($omniFileFullPath & " does not exist.")
            return 1
    
    return 0

#Workaround to pass custom version string
clCfg.version = version_flag

#Dispatch the omni function as the CLI one
dispatch(
    omni,

    short={
        "version" : 'v',
        "outName" : 'n',
        "performBits" : 'b',
        "importModule" : 'm',
        "exportIO" : 'i'
    },
    
    help={
        "outName" : "Name for the output library. It defaults to the name of the input file with 'lib' prepended to it (e.g. 'OmniSaw.omni' -> 'libOmniSaw" & $shared_lib_extension & "'). This flag doesn't work for directories or multiple files.",
        "outDir" : "Output folder. Defaults to the one in of the Omni file(s).",
        "lib" : "Build a shared or static library.",
        "architecture" : "Build architecture.",
        "compiler" : "Select a different C backend compiler to use. Omni supports all of Nim's C supported compilers.",
        "performBits" : "Set precision for ins and outs in the init and perform blocks. Accepted values are '32', '64' or '32/64'.",
        "wrapper" : "Specify an Omni wrapper to use.",
        "define" : "Define additional symbols for the intermediate Nim compiler.",
        "importModule" : "Import additional Nim modules to be compiled with the Omni file(s).",
        "exportHeader" : "Export the 'omni.h' header file together with the compiled lib.",
        "exportIO" : "Export the 'omni_io.txt' file together with the compiled lib."
    }
)
