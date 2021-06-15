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

import #[ osproc, ]# math, asyncdispatch, httpclient

proc toMb(num : SomeNumber) : float =
  return round(float(num) / 1048576.0, 1)

proc onProgressChanged(total, progress, speed: BiggestInt) {.async.} =
  echo("Progress: ", progress.toMb, " / ", total.toMb, " mb")
  echo("Speed: ", speed.toMb, " mb/s\n")

proc downloadZig() : Future[bool] {.async.} =
  let client = newAsyncHttpClient()
  client.onProgressChanged = onProgressChanged

  when defined(Linux):
    let os = "linux"
  elif defined(MacOS) or defined(MacOSX):
    let os = "macos"
  elif defined(Windows):
    let os = "windows"
  else:
    {.fatal: "invalid OS: " & hostOS.}

  when hostCPU == "amd64":
    let cpu = "x86_64"
  elif hostCPU == "arm64":
    let cpu = "aarch64"
  else:
    let cpu = hostCPU

  let link = "https://ziglang.org/download/0.8.0/zig-" & os & "-" & cpu & "-0.8.0.tar.xz"

  echo "\nDownloading the zig compiler from https://ziglang.org ...\n"

  try:
    await downloadFile(client, link, "zig.tar.xz")
    return true
  except:
    echo "ERROR: no internet connection or invalid link: " & link & "\n"
    return false

discard waitFor downloadZig()

#let success = waitFor downloadZig()

# if success:
#   echo "Unpacking the tar file..."
#   let fail_tar = bool execCmd("tar -xf zig-0.8.0.tar.xz -C zig-0.8.0 --strip-component 1")
#   if fail_tar:
#     echo "ERROR: could not run the 'tar' command"
#   else:
#     echo "Done!"
