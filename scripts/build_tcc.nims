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

when not defined(no_tcc):
  withDir("tcc"):
    var tcc_cc_flags = "-O3 -flto"
    when defined(arch_amd64) or defined(arch_x86_64):
      tcc_cc_flags.add " -march=x86-64"
    elif defined(arch_i386): #needs testing
      tcc_cc_flags.add " -march=i386"
    # elif defined(arch_arm64): #needs testing
    # elif defined(arch_arm): #needs testing
    else: #default: native build
      tcc_cc_flags.add " -march=native -mtune=native" 
    
    echo "\nBuilding the tcc compiler...\n" 

    #configure 
    when defined(Windows):
      withDir("./win32"):
        exec "./build-tcc.bat" #Check if the flags are the same
    else:
      exec "./configure --extra-cflags=\"" & tcc_cc_flags & "\" --extra-ldflags=\"" & tcc_cc_flags & "\""
      exec "make"
