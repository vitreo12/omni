# MIT License
# 
# Copyright (c) 2020-2021 Francesco Cameli
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

import cligen, os, strutils

import omni_print_styled
import omni_nim_compiler

#Package version is passed as argument when building. It will be constant and set correctly
const 
    NimblePkgVersion {.strdefine.} = ""
    omni_ver = NimblePkgVersion

const omni_header_path_nimble = "~/.nimble/pkgs/omni_lang-" & omni_ver & "/omni_lang/core/omni.h"

#-v / --version
let version_flag = "Omni - version " & $omni_ver & "\n(c) 2020-2021 Francesco Cameli"

#Extension for static lib
when defined(Linux):
    const 
        lib_prepend          = "lib"
        static_lib_extension = ".a"
        shared_lib_extension = ".so"

elif defined(MacOSX) or defined(MacOS):
    const 
        lib_prepend          = "lib"
        static_lib_extension = ".a"
        shared_lib_extension = ".dylib"

elif defined(Windows):
    const 
        lib_prepend          = ""           #Windows doesn't prepend "lib" to libraries
        static_lib_extension = ".lib"
        shared_lib_extension = ".dll"

#Parse compilation output for Gc allocations and pretty print it with colors
proc parseAndPrintCompilationString(msg : string) : bool =
    #Turn Error: and Warning: into red bright(1m) Error: (ansi escape codes: https://forum.nim-lang.org/t/7002)
    var colored_msg = msg.multiReplace([("Error:", "\e[31;1mError:\e[0m"), ("Warning:", "\e[31;1mError:\e[0m"), ("ERROR:", "\e[31;1mERROR:\e[0m")])
    echo colored_msg

    #Check GcMem. --warningAsError doesn't work correctly, as it would print error even when there is not!
    if msg.contains("GcMem"):
        printError("Trying to allocate memory through Nim's Garbage Collector. This is not allowed in Omni. Use 'Data' for all your allocations.")
        return true

    return false

#full path
template absPath(path : untyped) : untyped =
    path.normalizedPath().expandTilde().absolutePath()

#Actual compiler
proc omni_single_file(is_multi : bool = false, fileFullPath : string, outName : string = "", outDir : string = "", lib : string = "shared", architecture : string = "native", performBits : string = "32/64", wrapper : string = "", define : seq[string] = @[], importModule : seq[string] = @[], passNim : seq[string] = @[],exportHeader : bool = true, exportIO : bool = false, silent : bool = false) : int =
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
        printError(fileFullPath & " is not an Omni file.")
        return 1
    
    var outDirFullPath : string
    if outDir == "": #Check if outDir is empty. Use .omni's file path in that case.
        outDirFullPath = omniFileDir
    else:
        outDirFullPath = outDir.absPath()
    
    #Check if dir exists
    if not outDirFullPath.dirExists():
        printError("outDir: " & outDirFullPath & " does not exist.")
        return 1

    #Check performBits argument
    if performBits != "32" and performBits != "64" and performBits != "32/64":
        printError("performBits: " & $performBits & " is invalid. Valid values are '32', '64' and '32/64'.")
        return 1

    #Check lib argument
    var lib_extension : string
    if lib == "shared":
        lib_extension = shared_lib_extension
    elif lib == "static":
        lib_extension = static_lib_extension
    else:
        printError("Invalid --lib argument: \"" & lib & "\". Use 'shared' to build a shared library, or 'static' to build a static one.")
        return 1

    #Set output name
    var outputName : string
    if outName == "":
        outputName = lib_prepend & omniFileName & lib_extension
    else:
        outputName = lib_prepend & outName & lib_extension
    
    #Export IO
    var 
        omni_io_name = omniFileName & "_io.txt"
        omni_io = outDirFullPath & "/" & omni_io_name

    #Paths to omni sources and zig compiler
    when defined(Linux):
      let omni_dir = "~/.local/share/omni/".absPath()
    else:
      let omni_dir = "~/Documents/omni/".absPath()

    let 
      omni_sources_dir = omni_dir & "/" & omni_ver
      omni_zig_dir = omni_dir & "/zig"

    #Actually execute compilation.
    let (compilationString, failedOmniCompilation) = omni_compile_nim_file(
        omni_dir,
        omni_sources_dir,
        omni_zig_dir,
        omniFileName,
        omniFileDir,
        fileFullPath,
        outputName,
        outDirFullPath,
        lib,
        architecture,
        performBits,
        wrapper,
        define,
        importModule,
        exportHeader,
        exportIO
    )

    #Path to compiled shared / static lib
    let pathToCompiledLib = outDirFullPath & "/" & outputName
    template removeCompiledLib() : untyped =
        removeFile(pathToCompiledLib)
        removeFile(omni_io)

    #Check for GcMem warnings and print errors out 
    if parseAndPrintCompilationString(compilationString):
        removeCompiledLib()
        if is_multi: printError("Failed compilation of '" & omniFileName & omniFileExt & "'.")
        return 1
    
    #Error code from execCmd is usually some 8bit number saying what error arises. It's not important for now.
    if failedOmniCompilation:
        #No need to removeCompiledLib() as compilation failed anyway
        if is_multi: printError("Failed compilation of '" & omniFileName & omniFileExt & "'.")
        return 1

    #If sample / perform are undefined, omni_io will not exist
    var failedOmniIOPerformCheck = true
    if fileExists(omni_io):
        failedOmniIOPerformCheck = false
        if not exportIO: removeFile(omni_io)

    if failedOmniIOPerformCheck:
        printError("Undefined 'perform' or 'sample' blocks.\n")
        removeCompiledLib()
        if is_multi: printError("Failed compilation of '" & omniFileName & omniFileExt & "'.")
        return 1

    #Export omni.h too
    if exportHeader:
        let 
          omni_header_path = omni_sources_dir & "/omni_lang/omni_lang/core/omni.h"
          omni_header_out_path = outDirFullPath & "/omni.h"
        copyFile(omni_header_path, omni_header_out_path)

    #Done!
    if not silent:
      printSuccess("'" & outputName & "' has been compiled to folder \"" & $outDirFullPath & "\".")

    return 0

#Unpack files arg and pass it to compiler
proc omni(files : seq[string], outName : string = "", outDir : string = "", lib : string = "shared", architecture : string = "native", performBits : string = "32/64", wrapper : string = "", define : seq[string] = @[], importModule : seq[string] = @[], passNim : seq[string] = @[], exportHeader : bool = true, exportIO : bool = false, silent : bool = false) : int =
    #no files provided, print --version
    if files.len == 0:
        echo version_flag
        return 0

    for omniFile in files:
        #Get full extended path
        let omniFileFullPath = omniFile.absPath()

        #If it's a file or list of files, compile it / them
        if omniFileFullPath.fileExists():
            #if just one file in CLI, also pass the outName flag
            if files.len == 1:
                return omni_single_file(false, omniFileFullPath, outName, outDir, lib, architecture, performBits, wrapper, define, importModule, passNim, exportHeader, exportIO, silent)
            else:
                if omni_single_file(true, omniFileFullPath, "", outDir, lib, architecture, performBits, wrapper, define, importModule, passNim, exportHeader, exportIO, silent) > 0:
                    return 1

        #If it's a dir, compile all .omni/.oi files in it
        elif omniFileFullPath.dirExists():
            for kind, dirFile in walkDir(omniFileFullPath):
                if kind == pcFile:
                    let 
                        dirFileFullPath = dirFile.absPath()
                        dirFileExt = dirFileFullPath.splitFile().ext
                    
                    if dirFileExt == ".omni" or dirFileExt == ".oi":
                        if omni_single_file(true, dirFileFullPath, "", outDir, lib, architecture, performBits, wrapper, define, importModule, passNim, exportHeader, exportIO, silent) > 0:
                            return 1

        else:
            printError($omniFileFullPath & " does not exist.")
            return 1
    
    return 0

#Pass custom version string
clCfg.version = version_flag

#Remove --help-syntax
clCfg.helpSyntax = ""

#Arguments string
let arguments = "Arguments:\n  Omni file(s) or folder."

#Ignore clValType
clCfg.hTabCols = @[ clOptKeys, #[clValType,]# clDflVal, clDescrip ]

#Dispatch the omni function as the CLI one
dispatch(
    omni,

    #Remove "Usage: ..."
    noHdr = true,
    
    #Custom options printing
    usage = version_flag & "\n\n" & arguments & "\n\nOptions:\n$options",

    short = {
        "version" : 'v',
        "outName" : 'n',
        "performBits" : 'b',
        "importModule" : 'm',
        "passNim" : 'p',
        "exportIO" : 'i'
    },
    
    help = {
        "help" : "CLIGEN-NOHELP",
        "version" : "CLIGEN-NOHELP",
        "outName" : "Name for the output library. Defaults to the name of the input file with 'lib' prepended to it (e.g. 'OmniSaw.omni' -> 'libOmniSaw" & $shared_lib_extension & "'). This argument does not work for directories or multiple files.",
        "outDir" : "Output folder. Defaults to the one of the Omni file(s) to compile.",
        "lib" : "Build a 'shared' or 'static' library.",
        "architecture" : "Build architecture.",
        "performBits" : "Set precision for 'ins' and 'outs' in the perform block. Accepted values are '32', '64' or '32/64'. Note that this option does not affect Omni's internal floating point precision.",
        "wrapper" : "Specify an Omni wrapper to use.",
        "define" : "Define additional symbols for the intermediate Nim compiler.",
        "importModule" : "Import additional Nim modules to be compiled with the Omni file(s).",
        "passNim" : "Pass additional flags to the intermediate Nim compiler.",
        "exportHeader" : "Export the 'omni.h' header file together with the compiled lib.",
        "exportIO" : "Export the IO txt file together with the compiled lib.",
        "silent" : "CLIGEN-NOHELP"
    }
)
