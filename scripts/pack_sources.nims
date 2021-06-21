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

mkDir("build")
withDir("build"):
  mkDir("omni")
  withDir("omni"):
    cpDir(getPkgDir() & "/omni_lang", getCurrentDir() & "/omni_lang")
    cpDir(getPkgDir() & "/omninim/omninim/lib", getCurrentDir() & "/lib")
  echo "\nZipping all Omni source files...\n" 
  when defined(Windows):
    exec "tar czf omni.tar.gz omni"
  else:
    exec "tar cJf omni.tar.xz omni"

  mkDir("compiler")
  withDir("compiler"):
    mkDir("tcc")
    withDir("tcc"):
      when defined(Windos):
        mvFile(getPkgDir() & "/tcc/win32/tcc".toExe, getCurrentDir() & "/tcc".toExe)
        cpDir(getPkgDir() & "/tcc/win32/include", getCurrentDir() & "/include")
        cpDir(getPkgDir() & "/tcc/win32/lib", getCurrentDir() & "/lib")
      else:
        mvFile(getPkgDir() & "/tcc/tcc".toExe, getCurrentDir() & "/tcc".toExe)
        cpDir(getPkgDir() & "/tcc/include", getCurrentDir() & "/include")
        cpDir(getPkgDir() & "/tcc/lib", getCurrentDir() & "/lib") #is lib necessary too?
  echo "Zipping the tcc compiler...\n"
  when defined(Windows):
    exec "tar czf compiler.tar.gz compiler"
  else:
    exec "tar cJf compiler.tar.xz compiler"
