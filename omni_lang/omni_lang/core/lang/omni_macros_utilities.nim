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

import macros

#Dirty way of turning a typed block of code into an untyped:
#Basically, what's needed is to turn all newSymNode into newIdentNode.
#Sym are already semantically checked, Idents are not...
#Maybe just replace Syms with Idents instead? It would be much safer than this...
proc typed_to_untyped*(code_block : NimNode) : NimNode {.inline, compileTime.} =
    return parseStmt(code_block.repr())

proc genSymUntyped*(str : string) : NimNode {.inline, compileTime.} =
    return parseStmt(repr(genSym(ident=str)))[0]

#Use it in place of expandMacros
macro omni_debug_macros*(code : typed) =
    error $(code.toStrLit)