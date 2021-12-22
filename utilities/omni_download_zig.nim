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

import ../utilities/omni_print_styled
import os, httpclient, strutils

proc zigTarExists() : bool =
  for kind, path in walkDir(getCurrentDir()):
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
  for kind, path in walkDir(getCurrentDir()):
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

template deleteZigTarIfExists() =
  if zigTarExists():
    removeFile(getZigTarName())

template renameZigDir() =
  for kind, path in walkDir(getCurrentDir()):
    let 
      pathSplit = path.splitFile
      pathname = pathSplit.name & pathSplit.ext #zig directory ends with version number, which is (falsely) interpreted as a file extension
    if kind == pcDir:
      if pathname.startsWith("zig"):
        moveDir(pathname, "zig")

#set dir to where script is
setCurrentDir(getAppDir())

#Check if link exists, perhaps os / cpu combo is wrong
if not zigTarExists():
  when defined(Linux):
    let OS = "linux"
    let ext = ".tar.xz"
  elif defined(MacOS) or defined(MacOSX):
    let OS = "macos"
    let ext = ".tar.xz"
  elif defined(Windows):
    let OS = "windows"
    let ext = ".zip"
  else:
    {.fatal: "invalid OS: " & hostOS.}

  when hostCPU == "amd64":
    let cpu = "x86_64"
  elif hostCPU == "arm64":
    let cpu = "aarch64"
  else:
    let cpu = hostCPU

  let link = "https://ziglang.org/download/0.9.0/zig-" & OS & "-" & cpu & "-0.9.0" & ext

  echo "\nDownloading the zig compiler from https://ziglang.org ...\n"

  var client = newHttpClient()
  let response = client.request(link, httpMethod=HttpHead).code
  if response.is4xx or response.is5xx:
    printError "Could not download the zig compiler. No connection or invalid link: " & link & "\n"
    deleteZigTarIfExists()
    quit 1

  #Link exists and connection works, download it
  let failed_curl = bool execShellCmd("curl " & link & " -o zig" & ext)

  if failed_curl:
    printError "Could not download the zig compiler. No connection or invalid link: " & link & "\n"
    deleteZigTarIfExists()
    quit 1

#Unpack it
if zigTarExists():
  echo "\nUnpacking the zig.tar file..."
  when defined(Windows):
    let failed_tar = bool execShellCmd("tar -xf zig.zip")
  else:
    let failed_tar = bool execShellCmd("tar -xf zig.tar.xz")
  if failed_tar:
    printError "Failed to unpack the zig compiler."
    deleteZigTarIfExists()
    quit 1
  if dirExists("zig"): removeDir("zig")
  renameZigDir()
  deleteZigTarIfExists()
  quit 0


