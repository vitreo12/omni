# MIT License
# 
# Copyright (c) 2020 Francesco Cameli
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

### Buffer implementation spec ###

# Buffer.innerInit*[S : SomeInteger](obj_type : typedesc[Buffer], input_num : S, omni_inputs : int) : Buffer

# template new*[S : SomeInteger](obj_type : typedesc[Buffer], input_num : S) : untyped =
#     innerInit(Buffer, input_num, omni_inputs) #omni_inputs belongs to the scope of the dsp module

# Buffer.get_buffer(buffer : Buffer, input_val : float32)
# when defined(multithread_buffer):
#   Buffer.unlock_buffer(buffer : Buffer)

# []
# []=

# Buffer.len()
# Buffer.size()
# Buffer.nchans()
# Buffer.samplerate()