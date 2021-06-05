# nim c -d:nimcore -d:selftest -d:release -d:danger nim_compiler.nim

include "nim_compiler.nim"
include "captureStdout"
import compiler/condsyms

proc omni_compile_nim_file*(fileFolderFullPath : string, fileFullPath : string, outName : string = "", outDir : string = "", lib : string = "shared", architecture : string = "native", performBits : string = "32/64", wrapper : string = "", define : seq[string] = @[], importModule : seq[string] = @[], passNim : seq[string] = @[],exportHeader : bool = true, exportIO : bool = false, silent : bool = false) : tuple[output: string, success: bool] =
  let conf = newConfigRef()

  ########################
  # Nim Compiler options #
  ########################

  #C compilation
  conf.command = "c"

  #Force gcc (to be replaced with zigcc)
  conf.cCompiler = ccGcc
  # defineSymbol(conf.symbols, "zigcc") #use the zigcc compiler (switched on in nim.cfg)

  #--gc:none (from commnds.nim -> processSwitch)
  conf.selectedGC = gcNone
  defineSymbol(conf.symbols, "nogc")

  #-d:release (from commands.nim -> specialDefine)
  defineSymbol(conf.symbols, "release")
  conf.options.excl {optStackTrace, optLineTrace, optLineDir, optOptimizeSize}
  conf.globalOptions.excl {optExcessiveStackTrace, optCDebug}
  conf.options.incl optOptimizeSpeed

  #-d:danger (from commands.nim -> specialDefine)
  defineSymbol(conf.symbols, "danger")
  conf.options.excl {optObjCheck, optFieldCheck, optRangeCheck, optBoundsCheck, optOverflowCheck, optAssert, optStackTrace, optLineTrace, optLineDir}
  # conf.globalOptions.excl {optCDebug}

  #--opt:speed (from commands.nim -> processSwitch) 
  incl(conf.options, optOptimizeSpeed)
  excl(conf.options, optOptimizeSize)

  #--app:lib (from commands.nim -> processSwitch)
  if lib == "shared":
    incl(conf.globalOptions, optGenDynLib)
    excl(conf.globalOptions, optGenGuiApp)
    defineSymbol(conf.symbols, "library")
    defineSymbol(conf.symbols, "dll")

  #-app:staticLib (from commands.nim -> processSwitch)
  elif lib == "static":
    incl(conf.globalOptions, optGenStaticLib)
    excl(conf.globalOptions, optGenGuiApp)
    defineSymbol(conf.symbols, "library")
    defineSymbol(conf.symbols, "staticlib")
    # incl(conf.globalOptions, optNoLinking)   #This is for zigcc: --noLinking, done afterwards.
    # incl(conf.globalOptions, optCompileOnly) #This is for zigcc: --compileOnly.
  
  
  ######################
  # C Compiler options #
  ######################
  
  #arch
  var real_architecture = "-march=" & $architecture
  if architecture == "native":
      real_architecture = real_architecture & " -mtune=native"
  #x86_64 / amd64 as aliases for x86-64
  elif architecture == "x86_64" or architecture == "amd64":
      real_architecture = "-march=x86-64"
  elif architecture == "none":
      real_architecture = ""

  #lto
  var lto : string
  when not defined(Windows): #MacOS / Linux
      lto = "-flto"
  else: #Windows
      lto = "-flto -ffat-lto-objects" #-ffat-lto-objects fixes issues with MinGW

  #Clang has problem with this. When using zig, this will be fine
  when not defined(MacOS) and not defined(MacOSX):
    defineSymbol(conf.symbols, "lto")

  conf.compileOptions = "-w -fPIC " & lto & " " & real_architecture #no warnings + lto + fPIC + arch
  conf.linkOptions = "-fPIC " & lto #lto + fPIC

  ###########
  # Imports #
  ###########

  #Wrapper

  
  ###########
  # Defines #
  ###########

  #omni_io


  #########
  # Paths #
  #########

  #These could all be calculated and set at compile time
  # conf.searchPaths = @[
  #   AbsoluteDir("~/.choosenim/toolchains/nim-1.4.8/lib/core".absPath())
  # ] #add search paths here for stdlib modules
  # conf.libpath = AbsoluteDir("~/.choosenim/toolchains/nim-1.4.8/lib".absPath())
  conf.projectPath = AbsoluteDir(fileFolderFullPath) #dir of input file
  conf.projectFull = AbsoluteFile(fileFullPath) #input file
  conf.outDir = AbsoluteDir(outDir) #output dir
  conf.outFile = RelativeFile(outName) #output file


  ########
  # Misc #
  ########

  #--noMain:on
  incl(conf.globalOptions, {optNoMain})
  
  #--panics:on
  incl(conf.globalOptions, {optPanics})
  defineSymbol(conf.symbols, "nimPanics")
  
  #--hints:off
  excl(conf.options, {optHints})

  #--stdout:on
  incl(conf.globalOptions, {optStdout}) 

  #--colors:off
  excl(conf.globalOptions, {optUseColors})

  #--warning[User]:off
  excl(conf.notes, warnUser)
  excl(conf.mainPackageNotes, warnUser)
  excl(conf.foreignPackageNotes, warnUser)

  #--warning[UnusedImport]:off
  excl(conf.notes, warnUnusedImportX)
  excl(conf.mainPackageNotes, warnUnusedImportX)
  excl(conf.foreignPackageNotes, warnUnusedImportX)


  ###############
  # Compilation #
  ###############

  #Actually run compilation
  var compilation_output : string
  captureStdout(compilation_output):
    nim_compile(newIdentCache(), conf)
  
  return (compilation_output, conf.errorCounter > 0)
