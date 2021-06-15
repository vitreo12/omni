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

#When defined(omni_embed), embed files in executable
when defined(omni_embed):
  const omni_tar = staticRead("build/omni.tar.xz")

template renameZigDir() =
  for kind, path in walkDir(getCurrentDir()):
    let 
      pathSplit = path.splitFile
      pathname = pathSplit.name & pathSplit.ext #zig directory ends with version number, which is (falsely) interpreted as a file extension
    if kind == pcDir:
      if pathname.startsWith("zig"):
        moveDir(pathname, "zig")

#Unpack all source files to the correct omni_dir, according to OS
proc omniUnpackSourceFiles*(omni_dir : string) =
  echo "\nUnpacking all Omni source files..."
  echo "This process will only be done once.\n"
  createDir(omni_dir)
  if dirExists(omni_dir):
    setCurrentDir(omni_dir)
    writeFile("omni.tar.xz", omni_tar) #unpack tar from const
    let failed_omni_tar = bool execShellCmd("tar -xf omni.tar.xz")
    if failed_omni_tar:
      echo "ERROR: could not unpack omni.tar.xz"
      quit 1
    setCurrentDir("omni")
    let failed_zig_tar = bool execShellCmd("tar -xf zig.tar.xz")
    if failed_zig_tar:
      echo "ERROR: could not unpack zig.tar.xz"
      quit 1
    renameZigDir()
  else:
    echo "ERROR: could not create the directory: " & omni_dir
    quit 1
