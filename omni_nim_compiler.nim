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

import os, strutils

import omninim/omninim

#Package version is passed as argument when building. It will be constant and set correctly
const 
    NimblePkgVersion {.strdefine.} = ""
    omni_ver = NimblePkgVersion

#Used when can't find the bundled version of omninim.
#omni_ver is available cause this file is included in omni.nim
const omninim_nimble = "~/.nimble/pkgs/omninim-" & omni_ver & "/omninim/omninim/lib"

proc omni_compile_nim_file*(fileFolderFullPath : string, fileFullPath : string, omniIoName : string, outName : string = "", outDir : string = "", lib : string = "shared", architecture : string = "native", performBits : string = "32/64", wrapper : string = "", defines : seq[string] = @[], imports : seq[string] = @[], exportHeader : bool = true, exportIO : bool = false) : tuple[output: string, failure: bool] =
  #Config file
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
  conf.globalOptions.excl {optCDebug}

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
    # incl(conf.globalOptions, optNoLinking)   #This is for zigcc: --noLinking
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

  #C compiler and linker additional options
  conf.compileOptions = "-w -fPIC " & lto & " " & real_architecture #no warnings + lto + fPIC + arch
  conf.linkOptions = "-fPIC " & lto #lto + fPIC

  ###########
  # Imports #
  ###########

  #omni_lang
  let omni_lang_bundle = getAppDir() & "/omni_lang/omni_lang"
  if dirExists(omni_lang_bundle):
    conf.implicitImports.add findModule(conf, omni_lang_bundle, toFullPath(conf, FileIndex(-3))).string
  else:
    conf.implicitImports.add findModule(conf, "omni_lang", toFullPath(conf, FileIndex(-3))).string
  
  #wrapper
  if not wrapper.isEmptyOrWhitespace:
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

  let omninim_bundle = getAppDir() & "/omninim/omninim/omninim/lib"
  if dirExists(omninim_bundle):
    conf.libpath = AbsoluteDir(omninim_bundle)
  else:
    conf.libpath = AbsoluteDir(omninim_nimble)

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
  let failure = omniNimCompile(newIdentCache(), conf)

  #Error string is contained in conf.compilationOutput
  return (conf.compilationOutput, failure)
