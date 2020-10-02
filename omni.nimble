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

version       = "0.2.1"
author        = "Francesco Cameli"
description   = "omni is a DSL for low-level audio programming."
license       = "MIT"

requires "nim >= 1.0.0"
requires "cligen >= 0.9.41"

#Ignore omni_lang
skipDirs = @["omni_lang"]

#Install examples
installDirs = @["examples"]

#Compiler executable
bin = @["omni"]

#If using "nimble install" instead of "nimble installOmni", make sure omni-lang is still getting installed
before install:
  withDir(getPkgDir() & "/omni_lang"):
    exec "nimble install"

#before/after are BOTH needed for any of the two to work
after install:
  discard
    
#As nimble install, but with -d:release, -d:danger and --opt:speed. Also installs omni_lang.
task installOmni, "Install the omni-lang package and the omni compiler":
  #Build and install the omni compiler executable. This will also trigger the "before install" to install omni_lang
  exec "nimble install --passNim:-d:release --passNim:-d:danger --passNim:--opt:speed"

#Needed for the walkDir function
import os

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

task test, "Execute all tests":
  let testsDir = getPkgDir() & "/tests"
  runTestsInFolder(testsDir, true)

#Install the omni compiler executable before running the tests on CI 
before testCI:
  exec "nimble install" 

task testCI, "Run tests on CI: it installs omni / omni_lang first":
  exec "nimble test"

#before/after are BOTH needed for any of the two to work
after testCI:
  discard
