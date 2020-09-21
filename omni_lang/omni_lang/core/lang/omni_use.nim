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

#This could perhaps support untyped in the future

#This is what require does: 
#import "ImportMe.nim" as ImportMe_module
#Otherwise, module names will cluster the namespace if they have same name as structs, or defs

proc check_valid_path(path : NimNode, unified_path_list : var seq[NimNode], as_names : var seq[NimNode]) : void {.compileTime.} =
    let path_kind = path.kind
    
    if path_kind != nnkStrLit and path_kind != nnkIdent and path_kind != nnkInfix:
        error("require: invalid syntax. Only strings or identifiers are valid to set the paths.")
    
    #Custom as
    if path_kind == nnkInfix:
        let 
            infix_name = path[0].strVal()
            path_name  = path[1]
            module_as_name = path[2]

        if infix_name != "as":
            error("require: invalid infix '" & $infix_name & "'")

        if path_name.kind != nnkStrLit and path.kind != nnkIdent:
            error("require: invalid syntax. Only strings or identifiers are valid to set the paths.")

        if module_as_name.kind != nnkIdent:
            error("require: invalid module name")
        
        let module_as_name_module_inner = newIdentNode(module_as_name.strVal() & "_module_inner")

        unified_path_list.add(path_name)
        as_names.add(module_as_name_module_inner)

    #String or ident
    else:
        let path_without_extension = (path.strVal().splitFile().name)
        unified_path_list.add(path)
        as_names.add(newIdentNode(path_without_extension & "_module_inner"))

proc check_valid_paths(path_list : NimNode, paths_same_line : NimNode, unified_path_list : var seq[NimNode], as_names : var seq[NimNode]) : void {.compileTime.} =
    if path_list.len == 0:
        check_valid_path(path_list, unified_path_list, as_names)
    else:
        for path in path_list:
            check_valid_path(path, unified_path_list, as_names)
    
    #varargs: require "One.omni", "Two.omni"
    for path in paths_same_line:
        check_valid_path(path, unified_path_list, as_names)

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

    error "ye"