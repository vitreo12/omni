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
# import std/sha1

import ../omni_print_styled

import omni_sources_tar
import omni_zig_tar

when defined(Windows):
  import omni_strip_tar

#Rename the zig-linux(...) directory to just zig
template renameZigDir() =
  if dirExists("zig"):
    removeDir("zig")
  for kind, path in walkDir(getCurrentDir()):
    let 
      pathSplit = path.splitFile
      pathname = pathSplit.name & pathSplit.ext #zig directory ends with version number, which is (falsely) interpreted as a file extension
    if kind == pcDir:
      if pathname.startsWith("zig"):
        moveDir(pathname, "zig")

# template checkZigSha() =
#   echo $secureHashFile("zig.tar.xz")

proc omniUnpackZig(omni_dir : string) =
  echo "\nUnpacking the Zig compiler..."

  let omni_zig_dir = omni_dir & "/zig"
  createDir(omni_zig_dir)

  if dirExists(omni_zig_dir):
    try:
      omniUnpackZigTar()
    except OmniStripException:
      printError "The Zig compiler has already been unpacked. If you have deleted it, run `omni download` to download it again. It will be installed to: '" & omni_zig_dir & "'"
      quit 1

    when defined(Windows):
      let omni_zig_tar = "zig.tar.gz"
    else:
      let omni_zig_tar = "zig.tar.xz"

    let failed_zig_tar = bool execShellCmd("tar -xf " & omni_zig_tar)

    if failed_zig_tar:
      printError "Could not unpack the zig tar file"
      quit 1

    renameZigDir()

    removeFile(omni_zig_tar)

  else:
    printError "Could not create the directory: " & omni_zig_dir
    quit 1

proc omniUnpackSources(omni_dir : string, omni_ver : string) =
  echo "\nUnpacking all Omni source files..."

  omniUnpackSourcesTar()

  when defined(Windows):
    let omni_sources_tar = "omni.tar.gz"
  else:
    let omni_sources_tar = "omni.tar.xz"

  let failed_omni_tar = bool execShellCmd("tar -xf " & omni_sources_tar)

  if failed_omni_tar:
    printError "Could not unpack the omni tar file"
    quit 1

  #Call folder with omni_ver
  moveDir("omni", omni_ver)

  removeFile(omni_sources_tar)

when defined(Windows):
  proc omniUnpackStrip(omni_dir : string) =
    echo "\nUnpacking the strip utility..."

    omniUnpackStripTar()

    let omni_strip_tar = "strip.tar.gz"

    let failed_omni_strip_tar = bool execShellCmd("tar -xf " & omni_sources_tar)

    if failed_omni_strip_tar:
      printError "Could not unpack the strip tar file"
      quit 1

    removeFile(omni_strip_tar)

proc executeStripCmd() =
  when defined(Windows):
    omniUnpackStrip(omni_dir)
    let omni_strip_cmd = "./strip/strip.exe -R .omni_zig_tar " & getAppFilename().normalizedPath().expandTilde().absolutePath()
  else:
    let omni_strip_cmd = "strip -R .omni_zig_tar " & getAppFilename().normalizedPath().expandTilde().absolutePath()

  echo "\nExecuting the strip command..."
  let failed_omni_strip_cmd = bool execShellCmd(omni_strip_cmd)

  if failed_omni_strip_cmd:
    printError "Failed to strip the omni executable"
    quit 1

  echo ""

#Unpack all source files to the correct omni_dir, according to OS and omni_ver
proc omniUnpackAllFiles*(omni_dir : string, omni_ver : string) =
  echo "\nUnpacking the Zig compiler and all Omni source files. This process will only be executed once."
  if not dirExists(omni_dir):
    createDir(omni_dir)
    setCurrentDir(omni_dir)
    omniUnpackZig(omni_dir)
    omniUnpackSources(omni_dir, omni_ver)
    executeStripCmd()
  else:
    printError "Could not create the directory: " & omni_dir
    quit 1
