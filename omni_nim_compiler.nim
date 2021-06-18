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

import omni_unpack

const 
    NimblePkgVersion {.strdefine.} = ""
    omni_ver = NimblePkgVersion

# const nimble_pkgs_tilde = "~/.nimble/pkgs/"

template absPath(path : untyped) : untyped =
    path.normalizedPath().expandTilde().absolutePath()

proc omni_compile_nim_file*(omniFileName : string, fileFolderFullPath : string, fileFullPath : string, outName : string = "", outDir : string = "", lib : string = "shared", architecture : string = "native", performBits : string = "32/64", wrapper : string = "", defines : seq[string] = @[], imports : seq[string] = @[], exportHeader : bool = true, exportIO : bool = false) : tuple[output: string, failure: bool] =
  #omni dir path
  when defined(Linux):
    let omni_dir = "~/.local/share/omni/".absPath()
  else:
    let omni_dir = "~/Documents/omni/".absPath()

  let 
    omni_sources_dir = omni_dir & "/" & omni_ver
    omni_zig_dir = omni_dir & "/zig"
  
  #Unpack files if needed
  if not dirExists(omni_sources_dir):
    omniUnpackAllFiles(omni_dir, omni_ver)

  #Config file
  let conf = newConfigRef()

  ########################
  # Nim Compiler options #
  ########################

  #C compilation
  conf.command = "c"

  #Use Zig
  conf.cCompilerPath = omni_zig_dir
  conf.cCompiler = ccOmniZigcc

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

  
  #########
  # Paths #
  #########
  
  #nimble path (so that --import from a nimble pkg works)
  # let nimble_pkgs = nimble_pkgs_tilde.absPath()
  # if dirExists(nimble_pkgs):
  #   nimblePath(conf, AbsoluteDir(nimble_pkgs), newLineInfo(FileIndex(-3), 0, 0))

  #system lib path
  let omninim_lib_dir = omni_sources_dir & "/omninim/omninim/lib"
  
  #There probably is a leaner way to set all these paths
  conf.libpath = AbsoluteDir(omninim_lib_dir)
  conf.searchPaths.insert(AbsoluteDir(omninim_lib_dir & "/core"), 0)
  conf.searchPaths.insert(AbsoluteDir(omninim_lib_dir & "/posix"), 0)
  conf.searchPaths.insert(AbsoluteDir(omninim_lib_dir & "/pure"), 0)
  conf.searchPaths.insert(AbsoluteDir(omninim_lib_dir & "/pure/collections"), 0)
  conf.searchPaths.insert(AbsoluteDir(omninim_lib_dir & "/pure/concurrency"), 0)

  #don't set conf.projectName as that would expect the extension to be .nim
  conf.projectPath = AbsoluteDir(fileFolderFullPath) #dir of input file
  conf.projectFull = AbsoluteFile(fileFullPath) #input file
  conf.outDir = AbsoluteDir(outDir) #output dir
  conf.outFile = RelativeFile(outName) #output file

  #nimcacheDir ... Manually patch the name cause setting conf.projectName would expect the extension to be .nim
  conf.nimcacheDir = AbsoluteDir(omni_dir & "/cache/" & omniFileName)


  ######################
  # C Compiler options #
  ######################
  
  #arch
  var c_architecture : string
  if architecture == "native":
      c_architecture = "-march=native -mtune=native"
  elif architecture == "x86-64" or architecture == "x86_64" or architecture == "amd64":
      c_architecture = "-march=x86-64"
      conf.target.targetCPU = cpuAmd64
  elif architecture == "i386":
      c_architecture = "--target=i386"
      conf.target.targetCPU = cpuI386
  elif architecture == "aarch64":
      c_architecture = "--target=aarch64" #-march needs to be tested on arm. not so sure about --target either
      conf.target.targetCPU = cpuArm64
  elif architecture == "arm64":
      c_architecture = "--target=arm64" #-march needs to be tested on arm. not so sure about --target either
      conf.target.targetCPU = cpuArm64
  elif architecture == "arm":
      c_architecture = "--target=arm" #-march needs to be tested on arm. not so sure about --target either
      conf.target.targetCPU = cpuArm
  elif architecture == "wasm" or architecture == "wasm32": #doesn't work on zig, just leaving it here for the future
      c_architecture = "--target=wasm32"
      conf.target.targetCPU = cpuWasm32
  elif architecture == "none":
      c_architecture = ""
      conf.target.targetCPU = cpuNone
  else:
      c_architecture = "--target=" & architecture

  #lto
  var lto : string
  when not defined(Windows): #MacOS / Linux
      lto = "-flto"
  else: #Windows
      lto = "-flto -ffat-lto-objects" #-ffat-lto-objects fixes issues with MinGW

  #Clang has problem with this. When using zig, this will be fine
  # when not defined(MacOS) and not defined(MacOSX):
  defineSymbol(conf.symbols, "lto")

  #C compiler and linker additional options
  conf.compileOptions = "-w -fPIC " & lto & " " & c_architecture #no warnings + lto + fPIC + arch
  conf.linkOptions = "-fPIC " & lto #lto + fPIC

  
  ###########
  # Imports #
  ###########

  #omni_lang
  let omni_lang_dir = omni_dir & "/omni_lang/omni_lang"
  conf.implicitImports.add findModule(conf, omni_lang_dir, toFullPath(conf, FileIndex(-3))).string
  
  #wrapper
  if not wrapper.isEmptyOrWhitespace:
    let omni_wrapper_dir = omni_dir & "/wrappers/" & wrapper & "/" & wrapper #omnicollider/omnicollider
    conf.implicitImports.add findModule(conf, omni_wrapper_dir, toFullPath(conf, FileIndex(-3))).string

  #user imports
  for import_user in imports:
    conf.implicitImports.add findModule(conf, import_user, toFullPath(conf, FileIndex(-3))).string

  
  ###########
  # Defines #
  ###########

  #omni_io
  var omniIoName = omniFileName & "_io.txt"
  defineSymbol(conf.symbols, "omni_export_io")
  defineSymbol(conf.symbols, "tempDir", outDir)
  defineSymbol(conf.symbols, "omni_io_name", omniIoName)

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
  let failure = omniNimCompile(conf)

  #Error string is contained in conf.compilationOutput
  return (conf.compilationOutput, failure)
