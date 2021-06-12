
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

version       = "0.4.1"
author        = "Francesco Cameli"
description   = "omni is a DSL for low-level audio programming."
license       = "MIT"

requires "nim >= 1.4.0"
requires "cligen >= 1.5.0"

#Ignore omni_lang, omninim, misc folders
skipDirs = @["omni_lang", "omninim", "omnizig", "misc"]

#Install examples
installDirs = @["examples"]

#Compiler executable
bin = @["omni"]


#########
# Build #
#########

#walkDir / startsWith / endsWith
import os, strutils

#Before build
before build:
  #Download the zig compiler
  withDir(getPkgDir() & "/omnizig"):
    exec "nim c -r downloadZig.nim"
    var success = false
    for kind, path in walkDir("./"):
      if path.startsWith("./zig") and path.endsWith("tar.xz"): #file downloaded correctly
        success = true
    if not success: #failed download, exit the entire build process
      quit 1
  
  #Install omni_lang (in case user uses omni from nimble)
  withDir(getPkgDir() & "/omni_lang"):
    exec "nimble install -Y"

  #Install omninim (in case user uses omni from nimble)
  withDir(getPkgDir() & "/omninim"):
    exec "nimble install -Y"
  
  #remove build directory if exists
  if dirExists(getPkgDir() & "/build"):
    rmDir(getPkgDir() & "/build")

#After build
after build:
  #create build directory and move relevant binaries / folders there
  withDir(getPkgDir()):
    mkDir("build")
    withDir("build"):
      mkDir("omni")
      withDir("omni"):
        cpFile((getPkgDir() & "/omni").toExe, (getCurrentDir() & "/omni").toExe) 
        #cpFile won't apply file exec permissions. File wouldn't be executable... Needs to see if
        #Windows works. Ticket at: https://github.com/nim-lang/Nim/issues/18211
        when defined(Linux) or defined(MacOS) or defined(MacOSX):
          exec "chmod +x ./omni"

        cpDir(getPkgDir() & "/omninim", getCurrentDir() & "/omninim")
        cpDir(getPkgDir() & "/omni_lang", getCurrentDir() & "/omni_lang")

 
#########
# Tests #
#########

#Run all tests in tests/ folder. To run tests, nim and omni_lang need to be installed on machine
proc runTestsInFolder(path : string, top_level : bool = false) : void =
  for kind, file in walkDir(path):
    let splitFile = file.splitFile
    if kind == pcFile:
      if splitFile.ext == ".nim":
        exec ("nim c -r " & file)
    elif kind == pcDir:
      if top_level and splitFile.name == "utils": #skip top level "utils" folder
        continue
      runTestsInFolder(file, false)

#Run tests
task test, "Execute all tests":
  let testsDir = getPkgDir() & "/tests"
  runTestsInFolder(testsDir, true)
