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

import macros, os

#use "Path.omni":
    #Something as Something1 
    #someFunc as someFunc1
macro use*(path : untyped, ident_list : untyped = nil) : untyped =
    var import_name_without_extension : string

    #"ImportMe.omni" or ImportMe
    if path.kind == nnkStrLit or path.kind == nnkIdent:
        import_name_without_extension = path.strVal().splitFile().name
    
    #../../ImportMe
    elif path.kind == nnkPrefix:
        if path.last().kind != nnkIdent:
            error "use: Invalid path syntax " & repr(path)

        import_name_without_extension = path[^1].strVal()
    else:
        error "use: Invalid path syntax: " & repr(path)

    echo astGenRepr path
    
    for line in ident_list:
        echo astGenRepr line

    error repr result