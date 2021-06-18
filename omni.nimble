
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

version       = "0.5.0"
author        = "Francesco Cameli"
description   = "omni is a DSL for low-level audio programming."
license       = "MIT"

requires "nim >= 1.4.0"
requires "cligen >= 1.5.0"

#Ignore omni_lang, omninim, misc folders
skipDirs = @["omni_lang", "omninim", "embed", "utilities", "misc"]

#Install examples
installDirs = @["examples"]

#Compiler executable
bin = @["omni"]


#########
# Build #
#########

#walkDir / startsWith / endsWith
import os, strutils

proc zigTarExists() : bool =
  for kind, path in walkDir(getPkgDir() & "/utilities"):
    let 
      pathSplit = path.splitFile
      pathname = pathSplit.name
      pathext = pathSplit.ext
    when defined(Windows):
      if pathname.startsWith("zig") and pathext == ".zip":
        return true
    else:
      if pathname.startsWith("zig") and pathext == ".xz":
        return true
  return false

proc getZigTarName() : string =
  for kind, path in walkDir(getPkgDir() & "/utilities"):
    let 
      pathSplit = path.splitFile
      pathname = pathSplit.name
      pathext = pathSplit.ext
    when defined(Windows):
      if pathname.startsWith("zig") and pathext == ".zip":
        return pathname & pathext
    else:
      if pathname.startsWith("zig") and pathext == ".xz":
        return pathname & pathext

proc stripTarExists() : bool =
  for kind, path in walkDir(getPkgDir() & "/utilities"):
    let 
      pathSplit = path.splitFile
      pathname = pathSplit.name
      pathext = pathSplit.ext
    if pathname.startsWith("strip") and pathext == ".gz":
      return true
  return false

proc getStripTarName() : string =
  for kind, path in walkDir(getPkgDir() & "/utilities"):
    let 
      pathSplit = path.splitFile
      pathname = pathSplit.name
      pathext = pathSplit.ext
    if pathname.startsWith("strip") and pathext == ".gz":
      return pathname & pathext

#pre-build setup
before build:
  #Download the zig compiler
  withDir(getPkgDir() & "/utilities"):
    if not zigTarExists():
      exec "nim c -r omni_download_zig.nim"
      var success = false
      if zigTarExists():
          success = true
      if not success: #failed download, exit the entire build process
        quit 1

    #If windows, download strip too
    when defined(Windows):
      exec "nim c -r omni_download_strip.nim"
      var success_strip = false
      if stripTarExists():
          success_strip = true
      if not success_strip: #failed download, exit the entire build process
        quit 1
  
  #Copy the zig .tar and create the .tar file for the source files. On windows, strip is also copied
  #over.
  withDir(getPkgDir()):
    mkDir("build")
    withDir("build"):
      cpFile(getPkgDir() & "/utilities/" & getZigTarName(), getCurrentDir() & "/" & getZigTarName())
      # rmFile(getPkgDir() & "/utilities/" & getZigTarName())
      when defined(Windows):
        cpFile(getPkgDir() & "/utilities/" & getStripTarName(), getCurrentDir() & "/" & getStripTarName())
        # rmFile(getPkgDir() & "/utilities/" & getStripTarName())
      mkDir("omni")
      withDir("omni"):
        cpDir(getPkgDir() & "/omninim", getCurrentDir() & "/omninim")
        cpDir(getPkgDir() & "/omni_lang", getCurrentDir() & "/omni_lang")
      echo "\nZipping all Omni source files...\n" 
      when defined(Windows):
        exec "tar czf omni.tar.gz omni/"
      else:
        exec "tar cJf omni.tar.xz omni/"

  #Install omni_lang (used for tests, mainly)
  withDir(getPkgDir() & "/omni_lang"):
    exec "nimble install -Y"


#########
# Tests #
#########

#Run all tests in tests/ folder. To run tests, nim and omni_lang need to be installed on machine
proc runTestsInFolder(path : string, top_level : bool = false) : void =
  for kind, file in walkDir(path):
    let splitFile = file.splitFile
    if kind == pcFile:
      if splitFile.ext == ".nim" or splitFile.ext == ".omni" or splitFile.ext == "oi":
        exec ("nim c -r " & file)
    elif kind == pcDir:
      if top_level and splitFile.name == "utils": #skip top level "utils" folder
        continue
      runTestsInFolder(file, false)

#Run tests
task test, "Execute all tests":
  let testsDir = getPkgDir() & "/tests"
  runTestsInFolder(testsDir, true)
