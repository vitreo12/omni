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
proc printErrorMsg(msg : string) : void =
    setForegroundColor(fgRed)
    writeStyled("ERROR: ", {styleBright}) 
    setForegroundColor(fgWhite, true)
    writeStyled(msg)

#Generic success proc
proc printDone(msg : string) : void =
    setForegroundColor(fgGreen)
    writeStyled("DONE! ", {styleBright}) 
    setForegroundColor(fgWhite, true)
    writeStyled(msg)

#Actual compiler
proc omni(file : string, architecture : string = "native", lib : string = "shared", outDir : string = "./") : void =
    echo file
    echo architecture
    echo lib 

#Unpack files arg and pass it to compiler
proc omni_cli(files : seq[string], architecture : string = "native", lib : string = "shared", outDir : string = "./") : void =
    for file in files:
        omni(file, architecture, lib, outDir)

#Dispatch the omni function as the CLI one
dispatch(omni_cli, 

    help={ "architecture" : "Build architecture.",
           "lib" : "Build a shared or static library",
           "outDir" : "Output folder"
    }

)