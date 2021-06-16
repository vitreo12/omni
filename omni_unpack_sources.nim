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
import std/sha1

when defined(omni_embed):
  # const omni_tar = staticRead("build/omni.tar.xz")
  {.emit:"""STRING_LITERAL(omni_tar_xz, "omni.tar.xz", 11);""".}
  {.emit:["""__attribute__((section(".omni_tar,\"aw\""))) STRING_LITERAL(omni_tar,"""", staticRead("omni_tar.txt").static, "\",", staticRead("omni_tar_len.txt").static, ");"].}

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

template checkZigSha() =
  echo $secureHashFile("zig.tar.xz")

proc writeFileExport(name : string, contents : string) : void {.exportc.} =
  writeFile(name, contents)

#Unpack all source files to the correct omni_dir, according to OS
proc omniUnpackSourceFiles*(omni_dir : string) {.exportc.}=
  echo "\nUnpacking all Omni source files..."
  echo "This process will only be done once.\n"
  createDir(omni_dir)
  if dirExists(omni_dir):
    setCurrentDir(omni_dir)
    {.emit: "writeFileExport(((NimStringDesc*) &omni_tar_xz), ((NimStringDesc*) &omni_tar));"}
    # writeFile("omni.tar.xz", {.emit: "omni_tar".}) #unpack tar from const
    let failed_omni_tar = bool execShellCmd("tar -xf omni.tar.xz")
    if failed_omni_tar:
      echo "ERROR: could not unpack omni.tar.xz"
      quit 1
    setCurrentDir("omni")
    checkZigSha()
    when defined(Windows):
      let failed_zig_tar = bool execShellCmd("tar -xf zig.zip")
    else:
      let failed_zig_tar = bool execShellCmd("tar -xf zig.tar.xz")
    if failed_zig_tar:
      echo "ERROR: could not unpack zig.tar.xz"
      quit 1
    renameZigDir()
  else:
    echo "ERROR: could not create the directory: " & omni_dir
    quit 1
