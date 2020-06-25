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

#require "path1", "path2" AND require: 
macro require*(path_list : untyped, paths : varargs[typed]) : untyped =
    
    var unified_path_list : seq[NimNode]

    if path_list.len == 0:
        if path_list.kind != nnkStrLit:
            error("'require' only accepts strings to set the paths.")
        unified_path_list.add(path_list)
    else:
        for path in path_list:
            if path.kind != nnkStrLit:
                error("'require' only accepts strings to set the paths.")
            unified_path_list.add(path)

    for path in paths:
        if path.kind != nnkStrLit:
            error("'require' only accepts strings to set the paths.")
        unified_path_list.add(path)

    result = nnkStmtList.newTree()

    for path in unified_path_list:
        let omni_file_name = path.strVal().splitFile().name
        
        result.add(
            nnkImportStmt.newTree(
                path
            ),

            #Exporting the module is needed in order to access the entries
            #in the struct declared here...
            nnkExportStmt.newTree(
                newIdentNode(omni_file_name)
            )
        )