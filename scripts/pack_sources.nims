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

rmDir("build")
mkDir("build")
withDir("build"):
  #Omni source files and zig downloader
  mkDir("omni")
  withDir("omni"):
    cpDir(getPkgDir() & "/omni_lang", getCurrentDir() & "/omni_lang")
    cpDir(getPkgDir() & "/omninim/omninim/lib", getCurrentDir() & "/lib")
    #zig downloader
    withDir(getPkgDir() & "/utilities"):
      exec "nim c --warning[GcMem]:off omni_download_zig.nim"
    mvFile(getPkgDir() & "/utilities/omni_download_zig".toExe, getCurrentDir() & "/omni_download_zig".toExe) #gotta move cause cpFile doesn't copy permissions
  echo "\nZipping all Omni source files...\n" 
  when defined(Windows):
    exec "tar czf omni.tar.gz omni"
  else:
    exec "tar cJf omni.tar.xz omni"

  #tcc compiler
  when not defined(no_tcc):
    mkDir("tcc")
    withDir("tcc"):
      when defined(Windos):
        mvFile(getPkgDir() & "/tcc/win32/tcc".toExe, getCurrentDir() & "/tcc".toExe)
        cpDir(getPkgDir() & "/tcc/win32/include", getCurrentDir() & "/include")
        # cpDir(getPkgDir() & "/tcc/win32/lib", getCurrentDir() & "/lib") #is lib necessary too?
      else:
        mvFile(getPkgDir() & "/tcc/tcc".toExe, getCurrentDir() & "/tcc".toExe) #need to use mvFile cause cpFile does not copy file permissions...
        cpDir(getPkgDir() & "/tcc/include", getCurrentDir() & "/include")
        # cpDir(getPkgDir() & "/tcc/lib", getCurrentDir() & "/lib") #is lib necessary too?
        mvFile(getPkgDir() & "/tcc/libtcc.a", getCurrentDir() & "/libtcc.a") #need to use mvFile cause cpFile does not copy file permissions...
        mvFile(getPkgDir() & "/tcc/libtcc1.a", getCurrentDir() & "/libtcc1.a") #need to use mvFile cause cpFile does not copy file permissions...
    echo "Zipping the tcc compiler...\n"
    when defined(Windows):
      exec "tar czf tcc.tar.gz tcc"
    else:
      exec "tar cJf tcc.tar.xz tcc"


