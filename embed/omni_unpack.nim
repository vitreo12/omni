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

import os
import ../omni_print_styled
import omni_sources_tar

proc omniUnpackSources(omni_dir : string, omni_ver : string) : bool =
  echo "\nUnpacking all Omni source files..."

  omniUnpackSourcesTar()

  when defined(Windows):
    let omni_sources_tar = "omni.tar.gz"
  else:
    let omni_sources_tar = "omni.tar.xz"

  let failed_omni_tar = bool execShellCmd("tar -xf " & omni_sources_tar)

  if failed_omni_tar:
    printError "Could not unpack the omni tar file"
    return false

  #Call folder with omni_ver
  moveDir("omni", omni_ver)

  removeFile(omni_sources_tar)
  return true

#Unpack all source files to the correct omni_dir, according to OS and omni_ver
proc omniUnpackAllFiles*(omni_dir : string, omni_ver : string) : bool =
  echo "\nUnpacking the tcc compiler and all Omni source files. This process will only be executed once."
  if not dirExists(omni_dir):
    createDir(omni_dir)
  setCurrentDir(omni_dir)
  if not omniUnpackSources(omni_dir, omni_ver): return false
  createDir("wrappers")
  return true

proc omniUnpackFilesIfNeeded*(omni_dir : string, omni_sources_dir : string, omni_ver : string) : bool =
  #Unpack it all if the version for this release is not defined. 
  if not dirExists(omni_sources_dir):
    return omniUnpackAllFiles(omni_dir, omni_ver)

  return true

