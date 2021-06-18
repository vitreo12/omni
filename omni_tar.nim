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
  {.emit:
  """
#define STRING_LITERAL(name, str, length) \
  __attribute__((section(".omni_tar,\"aw\""))) static const struct {                   \
    TGenericSeq Sup;                      \
    NIM_CHAR data[(length) + 1];          \
} name = {{length, (NI) ((NU)length | NIM_STRLIT_FLAG)}, str}
  """ 
  .}

  #Embed the tar file
  when defined(Windows):
    const omni_tar_file* = staticRead("build/omni.tar.gz")
  else:
    const omni_tar_file* = staticRead("build/omni.tar.xz")

  #Throw / catch the exception where needed
  type OmniStripException* = ref object of CatchableError
    
  #Keep the write function local so that the const will be defined in this module, instead of being
  #copied over to where it's used! writeFile will raise an exception after 'strip' has been used
  proc omniUnpackTar*() =
    try:
      when defined(Windows):
        writeFile("omni.tar.gz", omni_tar_file) 
      else:
        writeFile("omni.tar.xz", omni_tar_file) 
    except:
      raise OmniStripException()
