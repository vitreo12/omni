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

import macros, omni_macros_utilities

proc find_and_replace_underscore(code_block : NimNode, new_val : NimNode) : void {.compileTime.} =
    for index, statement in code_block:
        var is_another_loop = false
        if statement.kind == nnkIdent:
            if statement.strVal() == "_":
                code_block[index] = new_val
        elif statement.kind == nnkCommand or statement.kind == nnkCall:
            let first_call = statement[0]
            if first_call.kind == nnkIdent:
                if first_call.strVal() == "loop":
                    is_another_loop = true
        #Don't run substitution on inner loops, as they are taken care of already by themselves!
        if not is_another_loop:
            find_and_replace_underscore(statement, new_val)

template when_stmt_loop(index, num) : untyped {.dirty.} =
    nnkWhenStmt.newTree(
        nnkElifBranch.newTree(
            nnkInfix.newTree(
                newIdentNode("is"),
                nnkCall.newTree(
                    newIdentNode("typeof"),
                    num
                ),
                newIdentNode("SomeNumber")
            ),
            nnkStmtList.newTree(
                nnkForStmt.newTree(
                    index,
                    nnkInfix.newTree(
                        newIdentNode("..<"),
                        newLit(0),
                        num
                    ),
                    code_block
                )
            )
        ),
        nnkElse.newTree(
            nnkStmtList.newTree(
                nnkForStmt.newTree(
                    index,
                    num,
                    code_block
                )
            )
        )
    )

proc omni_loop_inner*(loop_block : NimNode) : NimNode {.compileTime.} =
    let 
        loop_block_kind = loop_block.kind
        loop_block_len = loop_block.len

    if loop_block_kind == nnkCall or loop_block_kind == nnkCommand:
        #loop: ... infinite loop
        if loop_block_len == 2:
            let code_block = loop_block[1]
            return nnkWhileStmt.newTree(
                newIdentNode("true"),
                code_block
            )

        #loop(0..4)
        elif loop_block_len == 3:
            var 
                num = loop_block[1]
                num_kind = num.kind
                code_block = loop_block[2]

            if num_kind == nnkInfix:
                let infix_str = num[0].strVal()
                if infix_str == ".." or infix_str == "..<":
                    let unique_index = genSymUntyped("index")
                    find_and_replace_underscore(code_block, unique_index)
                    return nnkForStmt.newTree(
                        unique_index,
                        num,
                        code_block
                    )
                
                else:
                    error "loop: invalid infix: '" & infix_str & "'"
            
        #loop(i, 4) / loop(i, 0..4) / loop i, 4 / loop i, 0..4
        elif loop_block_len == 4:
            let 
                index = loop_block[1]
                index_kind = index.kind
                num = loop_block[2]
                num_kind = num.kind
                code_block = loop_block[3]
            
            if index_kind == nnkIdent:
                #loop(i, 4)
                if num_kind == nnkIntLit:
                    #use num_val: gcc will optimize the loop
                    let num_val = newLit(int(num.intVal()))
                    return nnkForStmt.newTree(
                        index,
                        nnkInfix.newTree(
                            newIdentNode("..<"),
                            newLit(0),
                            num_val
                        ),
                        code_block
                    )
                    
                #loop(i, a)... This returns a when statement to allow to use
                #loop(i, a) when a is not a number, but for example is Data
                elif num_kind == nnkIdent:
                    return when_stmt_loop(index, num)
                
                #loop(i, 0..4)
                elif num_kind == nnkInfix:
                    let infix_str = num[0].strVal()
                    if infix_str == ".." or infix_str == "..<":
                        return nnkForStmt.newTree(
                            index,
                            num,
                            code_block
                        )
                    
                    #other infixes, like operators
                    else:
                        return nnkForStmt.newTree(
                            index,
                            nnkInfix.newTree(
                              newIdentNode("..<"),
                              newLit(0),
                              num
                            ),
                            code_block
                        ) 

                #Any other case
                else:
                    return nnkForStmt.newTree(
                        index,
                        nnkInfix.newTree(
                           newIdentNode("..<"),
                           newLit(0),
                           num
                        ),
                        code_block
                    )
            else:
                error "loop: Invalid identifier '" & repr(index) & "' in ' " & repr(loop_block) & "'"

    if loop_block_len != 3:
        error "loop: Invalid syntax: '" & repr(loop_block) & "'"

    let 
        index_or_num = loop_block[1]
        index_or_num_kind = index_or_num.kind
        code_block = loop_block[2]

    let unique_index = genSymUntyped("index")

    #loop 4 / loop i 4 / loop variable / loop(4) / loop(variable) / loop 0..4 / loop i 0..4

    #loop 4
    if index_or_num_kind == nnkIntLit:
        #use num_val: gcc will optimize the loop
        let num_val = newLit(int(index_or_num.intVal()))
        find_and_replace_underscore(code_block, unique_index)
        return nnkForStmt.newTree(
            unique_index,
            nnkInfix.newTree(
                newIdentNode("..<"),
                newLit(0),
                num_val
            ),
            code_block
        )
    
    #loop a This returns a when statement to allow to use
    #loop a when a is not a number, but for example is Data
    elif index_or_num_kind == nnkIdent:
        find_and_replace_underscore(code_block, unique_index)
        return when_stmt_loop(unique_index, index_or_num)

    #loop 0..4
    elif index_or_num_kind == nnkInfix:
        let infix_str = index_or_num[0].strVal()
        find_and_replace_underscore(code_block, unique_index)
        if infix_str == ".." or infix_str == "..<":
            return nnkForStmt.newTree(
                unique_index,
                index_or_num,
                code_block
            ) 

    #loop i 4 / loop i 0..4
    elif index_or_num_kind == nnkCommand:
        let 
            index = index_or_num[0]
            index_kind = index.kind
            num = index_or_num[1]
            num_kind = num.kind

        if index_kind == nnkIdent:
            #loop i 4
            if num_kind == nnkIntLit:
                #use num_val: gcc will optimize the loop
                let num_val = newLit(int(num.intVal()))
                return nnkForStmt.newTree(
                    index,
                    nnkInfix.newTree(
                        newIdentNode("..<"),
                        newLit(0),
                        num_val
                    ),
                    code_block
                )

            #loop i a ... This returns a when statement to allow to use
            #loop i a when a is not a number, but for example is Data
            elif num_kind == nnkIdent:
                return when_stmt_loop(index, num)
            
            #loop i 0..4
            elif num_kind == nnkInfix:
                let infix_str = num[0].strVal()
                if infix_str == ".." or infix_str == "..<":
                    return nnkForStmt.newTree(
                        index,
                        num,
                        code_block
                    )
                
                #other infixes, like operators
                else:
                    return nnkForStmt.newTree(
                        index,
                        nnkInfix.newTree(
                          newIdentNode("..<"),
                          newLit(0),
                          num
                        ),
                        code_block
                    ) 

            #Any other case
            else:
                return nnkForStmt.newTree(
                    index,
                    nnkInfix.newTree(
                        newIdentNode("..<"),
                        newLit(0),
                        num
                    ),
                    code_block
                )
        else:
            error "loop: Invalid identifier '" & repr(index) & "' in ' " & repr(index_or_num) & "'"
    else:
        error "loop: Invalid syntax: '" & repr(loop_block) & "'"
