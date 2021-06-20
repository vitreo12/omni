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

when defined(omni_embed):
  #Redefining STRING_LITERAL to be including __attribute__(section).
  #It needs to be in its own module or it will overwrite all implementations of STRING_LITERAL
  #\"aw\" is what does the trick. Taken from: https://stackoverflow.com/questions/40372977/why-does-objcopy-exclude-one-section-but-not-another
  #Additionally, this macro defines get_addr_(length) functions for each string literal. Basically,
  #I only need the one for the "zig.tar.xz" string literal (get_addr_10). The volatile is NECESSARY
  #because otherwise the C compiler would optimize away the indexing, actually resulting in an
  #inlined value of the array data. In the case of stripping, all the strings in this module will be
  #removed, including things like "../build/zig.tar.xz" and "zig.tar.xz"
  {.emit:
  """
#define STRING_LITERAL(name, str, length) \
__attribute__((section(".omni_zig_tar,\"aw\""))) static const struct { \
    TGenericSeq Sup;                      \
    NIM_CHAR data[(length) + 1];          \
} name = {{length, (NI) ((NU)length | NIM_STRLIT_FLAG)}, str}; \ 
inline char get_addr_##length() { \
    volatile NIM_CHAR* string = &(name.data); \ 
    return string[0]; \
}
  """ 
  .}

  #Embed the tar file
  when defined(Windows):
    const omni_zig_tar_file* = staticRead("../build/zig.tar.gz")
  else:
    const omni_zig_tar_file* = staticRead("../build/zig.tar.xz")

  #Keep the write function local so that the const will be defined in this module, instead of being
  #copied over to where it's used! writeFile will raise an exception after 'strip' has been used
  proc omniUnpackZigTar*() : bool =
    try:
      when defined(Windows):
        writeFile("zig.tar.gz", omni_zig_tar_file) 
      else:
        writeFile("zig.tar.xz", omni_zig_tar_file) 
      return true
    except:
      return false

  #Import the function from C
  proc get_addr_10() : cchar {.importc.}
  
  #Check first entry is not 'z' (first letter of the "zig.tar.xz" string literal)
  #{.inline.} would fail the C compiler here, probably a bug with nim
  proc omniHasBeenStripped*() : bool =
    return get_addr_10() != 'z'
