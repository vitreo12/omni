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

proc loop_index_substitute(code_block : NimNode, index_original : NimNode, index_sub : NimNode) : void {.compileTime.} =
    for i, statement in code_block:
        if statement == index_original:
            code_block[i] = index_sub
        loop_index_substitute(statement, index_original, index_sub)

proc loop_unroll(code_block : NimNode, num : NimNode, index : NimNode) : NimNode {.compileTime.} =
    let num_val = num.intVal()
    
    var unique_index : NimNode         
    
    result = nnkStmtList.newTree()
        
    for i in 0..<num_val:
        if index.kind == nnkIdent:
            if i == 0:
                unique_index = genSym(ident=index.strVal())
                unique_index = parseExpr(repr(unique_index)) #need untyped repr
                result.add(
                    nnkWhenStmt.newTree(
                        nnkElifBranch.newTree(
                            nnkPrefix.newTree(
                                newIdentNode("not"),
                                nnkCall.newTree(
                                    newIdentNode("declaredInScope"),
                                    unique_index
                                )
                            ),
                            nnkStmtList.newTree(
                                nnkVarSection.newTree(
                                    nnkIdentDefs.newTree(
                                        unique_index,
                                        newIdentNode("int"),
                                        newLit(int(i))
                                    )
                                )
                            )
                        ),
                        nnkElse.newTree(
                            nnkStmtList.newTree(
                                nnkAsgn.newTree(
                                    unique_index,
                                    newLit(int(i))
                                )
                            )
                        )
                    )
                    
                )
            else:
                result.add(
                    nnkAsgn.newTree(
                        unique_index,
                        newLit(int(i))
                    )
                )
        
        #Needed for struct re-assigning!
        result.add(
            nnkBlockStmt.newTree(
                newEmptyNode(),
                code_block
            )
        )

    loop_index_substitute(result, index, unique_index)

    #Wrap the whole loop in block, so the scope is not polluted
    result = nnkBlockStmt.newTree(
        newEmptyNode(),
        result
    )
        
proc loop_inner*(loop_block : NimNode) : NimNode {.compileTime.} =
    if loop_block.kind == nnkCall:
        #loop(4, i)
        if loop_block.len == 4:
            let 
                num = loop_block[1]
                num_kind = num.kind
                index = loop_block[2]
                index_kind = index.kind
                code_block = loop_block[3]

            if index_kind == nnkIdent:
                #loop unroll
                if num_kind == nnkIntLit:
                    return loop_unroll(code_block, num, index)
                
                elif num_kind == nnkIdent:
                    return nnkForStmt.newTree(
                        index,
                        nnkInfix.newTree(
                            newIdentNode("..<"),
                            newLit(0),
                            num
                        ),
                        loop_block[3]
                    )
                else:
                    error "loop: Invalid number or identifier '" & repr(num) & "' in ' " & repr(loop_block) & "'"
            else:
                error "loop: Invalid identifier '" & repr(index) & "' in ' " & repr(loop_block) & "'"

    if loop_block.len != 3:
        error "loop: Invalid syntax: '" & repr(loop_block) & "'"

    let 
        index_or_num = loop_block[1]
        index_or_num_kind = index_or_num.kind

        code_block = loop_block[2]

    #loop 4 / loop variable / loop(4) / loop(variable)

    #loop unroll
    if index_or_num_kind == nnkIntLit:
        return loop_unroll(code_block, index_or_num, nil)
    
    elif index_or_num_kind == nnkIdent:
        var unique_index = genSym(ident="index")
        unique_index = parseExpr(repr(unique_index))
        
        return nnkForStmt.newTree(
            unique_index,
            nnkInfix.newTree(
                newIdentNode("..<"),
                newLit(0),
                index_or_num
            ),
            code_block
        )

    #loop 4 i
    elif index_or_num_kind == nnkCommand:
        let 
            num = index_or_num[0]
            num_kind = num.kind
            index = index_or_num[1]
            index_kind = index.kind

        if index_kind == nnkIdent:
            #loop unroll
            if num_kind == nnkIntLit:
                return loop_unroll(code_block, num, index)

            elif num_kind == nnkIdent:
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
                error "loop: Invalid number or identifier '" & repr(num) & "' in ' " & repr(index_or_num) & "'"
        else:
            error "loop: Invalid identifier '" & repr(index) & "' in ' " & repr(index_or_num) & "'"
    else:
        error "loop: Invalid syntax: '" & repr(loop_block) & "'"