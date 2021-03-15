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

import ../../omni_lang/omni_lang
import macros

#like expandMacros, but just return the string instead of printing
macro macroToNimCodeString*(body: typed) : untyped =
  result = body.toStrLit

#return a block of nim code as a parsed nim string
template omniToNimString*(body : untyped) : string =
  macroToNimCodeString:
    omni_parse_block_untyped(body) 

macro compareOmniNim_inner*(omni_parsed_code : typed, nim_code_block : typed) : untyped =
  let 
    omni_parsed_code_repr = astGenRepr(omni_parsed_code)
    nim_code = nim_code_block[1]
    nim_code_repr = astGenRepr(nim_code) #extract block
  
  echo repr omni_parsed_code
  echo repr nim_code
  echo ""

  if omni_parsed_code_repr == nim_code_repr:
    result = newLit(true)
  else:
    result = newLit(false)

#re-use template to delare same things
template omni_code_block() {.dirty.} =
  var 
    omni_code = code[0][1]
    
    #put nim_code in block (in order not repeat declarations)
    nim_code = nnkBlockStmt.newTree(
      newEmptyNode(),
      code[1][1]
    )

#generic code comparison
macro compareOmniNim*(code : untyped) : untyped =
  omni_code_block()

  return quote do:
    block:
      var
        samplerate     {.inject.} = 0.0
        bufsize        {.inject.} = 0
        omni_auto_mem  {.inject.} = cast[Omni_AutoMem](0) 
        omni_call_type {.inject.} : typedesc[Omni_InitCall]
      compareOmniNim_inner(omni_parse_block_untyped(`omni_code`), `nim_code`)

#init comparison
macro compareOmniNim_init*(code : untyped) : untyped =
  omni_code_block()

  return quote do:
    block:
      var
        samplerate     {.inject.} = 0.0
        bufsize        {.inject.} = 0
        omni_auto_mem  {.inject.} = cast[Omni_AutoMem](0) 
        omni_call_type {.inject.} : typedesc[Omni_InitCall]
      compareOmniNim_inner(omni_parse_block_untyped(`omni_code`, is_init_block_typed=true), `nim_code`)

#perform comparison
macro compareOmniNim_perform*(code : untyped) : untyped =
  omni_code_block()
  
  return quote do:
    block:
      var
        samplerate     {.inject.} = 0.0
        bufsize        {.inject.} = 0
        omni_auto_mem  {.inject.} = cast[Omni_AutoMem](0) 
        omni_call_type {.inject.} : typedesc[Omni_PerformCall]
      compareOmniNim_inner(omni_parse_block_untyped(`omni_code`, is_perform_block_typed=true), `nim_code`)
