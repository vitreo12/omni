# nim c -d:nimcore -d:release -d:danger nim_compiler.nim

import omninim

proc omni_compile_nim_file*(fileFolderFullPath : string, fileFullPath : string, omniIoName : string, outName : string = "", outDir : string = "", lib : string = "shared", architecture : string = "native", performBits : string = "32/64", wrapper : string = "", defines : seq[string] = @[], imports : seq[string] = @[], exportHeader : bool = true, exportIO : bool = false) : tuple[output: string, failure: bool] =
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

  #omni_lang
  conf.implicitImports.add findModule(conf, getAppDir() & "/omni_lang/omni_lang", toFullPath(conf, FileIndex(-3))).string
  
  #wrapper
  if wrapper.isEmptyOrWhitespace.not:
    conf.implicitImports.add findModule(conf, wrapper, toFullPath(conf, FileIndex(-3))).string

  #user imports
  for import_user in imports:
    conf.implicitImports.add findModule(conf, import_user, toFullPath(conf, FileIndex(-3))).string

  
  ###########
  # Defines #
  ###########

  #omni_io
  defineSymbol(conf.symbols, "omni_export_io")
  defineSymbol(conf.symbols, "tempDir:\"" & outDir & "\"")
  defineSymbol(conf.symbols, "omni_io_name:\"" & omniIoName & "\"")

  #performBits
  if performBits == "32":
    defineSymbol(conf.symbols, "omni_perform32")
  elif performBits == "64":
    defineSymbol(conf.symbols, "omni_perform64")
  else:
    defineSymbol(conf.symbols, "omni_perform32")
    defineSymbol(conf.symbols, "omni_perform64")

  #user defines
  for define_user in defines:
    defineSymbol(conf.symbols, define_user)

  #########
  # Paths #
  #########

  #These could all be calculated and set at compile time
  conf.libpath = AbsoluteDir(getAppDir() & "/nim/lib")
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
  # incl(conf.globalOptions, {optStdout}) 

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

  echo conf.errorCounter
  
  return (compilation_output, conf.errorCounter > 0)
