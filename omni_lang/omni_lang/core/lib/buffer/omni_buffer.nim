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
import ../../lang/omni_call_types
import ../auto_mem/omni_auto_mem

type
    Buffer_inherit* = object of RootObj
        input_num*  : int      
        length*     : int
        size*       : int
        chans*      : int
        samplerate* : float

    #Dummys for parser
    Buffer = object
    Buffer_struct_export = object

proc Buffer_struct_new_inner*[S : SomeInteger](input_num : S, buffer_interface : pointer, obj_type : typedesc[Buffer_struct_export], ugen_auto_mem : ptr OmniAutoMem, ugen_call_type : typedesc[CallType] = InitCall) : Buffer {.inline.} =
    {.fatal: "No wrapper defined for `Buffer`.".}

#This is quite an overhead, as it gets compiled even when not using Buffer. Find a way to not compile it in that case.
macro newBufferInterface*(code_block : untyped) : untyped =
    if code_block.kind != nnkStmtList:
        error "Invalid syntax for newBufferInterface. It must be a statement list."
    
    result = nnkStmtList.newTree()

    var 
        obj : NimNode
        init : NimNode
        lockFromInput : NimNode
        lockFromParam : NimNode
        unlockBuffer : NimNode
        getter : NimNode
        setter : NimNode

    for statement in code_block:
        if statement.kind != nnkCall or statement.len > 2:
            error "Invalid statement: '" & repr(statement) & "'. It must be a code block."

        let 
            statement_name = statement[0].strVal()
            statement_block = statement[1]

        if statement_name == "obj":
            var 
                buffer_struct_inner_rec_list = nnkRecList.newTree()
                buffer_struct_inner = nnkTypeDef.newTree(
                    nnkPostfix.newTree(
                        newIdentNode("*"),
                        newIdentNode("Buffer_struct_inner")
                    ),
                    newEmptyNode(),
                    nnkObjectTy.newTree(
                        newEmptyNode(),
                        nnkOfInherit.newTree(
                            newIdentNode("Buffer_inherit")
                        ),
                        buffer_struct_inner_rec_list
                    )
                )
            
            for entry in statement_block:
                assert entry.len == 2
                let ident_def = nnkIdentDefs.newTree(
                    entry[0],
                    entry[1][0],
                    newEmptyNode()
                )
                buffer_struct_inner_rec_list.add(ident_def)

            obj = nnkStmtList.newTree(
                nnkTypeSection.newTree(
                    buffer_struct_inner,
                    nnkTypeDef.newTree(
                        nnkPostfix.newTree(
                            newIdentNode("*"),
                            newIdentNode("Buffer")
                        ),
                        newEmptyNode(),
                        nnkPtrTy.newTree(
                            newIdentNode("Buffer_struct_inner")
                        )
                    ),
                    nnkTypeDef.newTree(
                        nnkPostfix.newTree(
                            newIdentNode("*"),
                            newIdentNode("Buffer_struct_export")
                        ),
                    newEmptyNode(),
                    newIdentNode("Buffer")
                    )
                )
            )

        elif statement_name == "init":
            var init_body = nnkStmtList.newTree(
                nnkWhenStmt.newTree(
                    nnkElifBranch.newTree(
                        nnkInfix.newTree(
                            newIdentNode("is"),
                            newIdentNode("ugen_call_type"),
                            newIdentNode("PerformCall")
                        ),
                        nnkStmtList.newTree(
                            nnkPragma.newTree(
                                nnkExprColonExpr.newTree(
                                    newIdentNode("fatal"),
                                    newLit("attempting to allocate memory in the `perform` or `sample` blocks for `struct Buffer`")
                                )
                            )
                        )
                    )
                ),
                nnkVarSection.newTree(
                    nnkIdentDefs.newTree(
                        newIdentNode("buffer"),
                        newEmptyNode(),
                        nnkCast.newTree(
                            newIdentNode("Buffer"),
                            nnkCall.newTree(
                                newIdentNode("omni_alloc"),
                                nnkCall.newTree(
                                    newIdentNode("culong"),
                                    nnkCall.newTree(
                                        newIdentNode("sizeof"),
                                        newIdentNode("Buffer_struct_inner")
                                    )
                                )
                            )
                        )
                    )
                ),
                nnkCall.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("ugen_auto_mem"),
                        newIdentNode("registerChild")
                    ),
                    newIdentNode("result")
                ),
                statement_block,
                nnkAsgn.newTree(
                    newIdentNode("result"),
                    newIdentNode("buffer")
                )
            )

            init = nnkStmtList.newTree(
                nnkProcDef.newTree(
                    nnkPostfix.newTree(
                        newIdentNode("*"),
                        newIdentNode("Buffer_struct_new_inner")
                    ),
                    newEmptyNode(),
                    nnkGenericParams.newTree(
                        nnkIdentDefs.newTree(
                            newIdentNode("S"),
                            newIdentNode("SomeInteger"),
                            newEmptyNode()
                        )
                    ),
                    nnkFormalParams.newTree(
                        newIdentNode("Buffer"),
                        nnkIdentDefs.newTree(
                            newIdentNode("input_num"),
                            newIdentNode("S"),
                            newEmptyNode()
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("buffer_interface"),
                            newIdentNode("pointer"),
                            newEmptyNode()
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("obj_type"),
                            nnkBracketExpr.newTree(
                                newIdentNode("typedesc"),
                                newIdentNode("Buffer_struct_export")
                            ),
                            newEmptyNode()
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("ugen_auto_mem"),
                            nnkPtrTy.newTree(
                                newIdentNode("OmniAutoMem")
                            ),
                            newEmptyNode()
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("ugen_call_type"),
                            nnkBracketExpr.newTree(
                                newIdentNode("typedesc"),
                                newIdentNode("CallType")
                            ),
                            newIdentNode("InitCall")
                        )
                    ),
                    nnkPragma.newTree(
                        newIdentNode("inline")
                    ),
                    newEmptyNode(),
                    init_body
                )
            )

        elif statement_name == "lockFromInput" or statement_name == "lock_from_input":
            lockFromInput = nnkStmtList.newTree(
                nnkProcDef.newTree(
                    nnkPostfix.newTree(
                        newIdentNode("*"),
                        newIdentNode("get_buffer") #must become get_buffer_in
                    ),
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("bool"),
                        nnkIdentDefs.newTree(
                            newIdentNode("buffer"),
                            newIdentNode("Buffer"),
                            newEmptyNode()
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("input_val"),
                            newIdentNode("float32"),
                            newEmptyNode()
                        )
                    ),
                    nnkPragma.newTree(
                        newIdentNode("inline")
                    ),
                    newEmptyNode(),
                    nnkStmtList.newTree(
                        statement_block
                    )
                )
            )
        
        elif statement_name == "lockFromParam" or statement_name == "lock_from_param":
            lockFromParam = nnkStmtList.newTree(
                nnkDiscardStmt.newTree(
                    newEmptyNode()
                )
            )

        elif statement_name == "unlock":
            unlockBuffer = nnkStmtList.newTree(
                nnkProcDef.newTree(
                    nnkPostfix.newTree(
                        newIdentNode("*"),
                        newIdentNode("unlock_buffer")
                    ),
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("void"),
                        nnkIdentDefs.newTree(
                            newIdentNode("buffer"),
                            newIdentNode("Buffer"),
                            newEmptyNode()
                        )
                    ),
                    nnkPragma.newTree(
                        newIdentNode("inline")
                    ),
                    newEmptyNode(),
                    nnkStmtList.newTree(
                        statement_block
                    )
                )
            )
        
        elif statement_name == "getter":
            getter = nnkStmtList.newTree(
                nnkProcDef.newTree(
                    nnkPostfix.newTree(
                        newIdentNode("*"),
                        newIdentNode("getter")
                    ),
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("float"),
                        nnkIdentDefs.newTree(
                            newIdentNode("buffer"),
                            newIdentNode("Buffer"),
                            newEmptyNode()
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("channel"),
                            newIdentNode("int"),
                            newLit(0)
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("index"),
                            newIdentNode("int"),
                            newLit(0)
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("ugen_call_type"),
                            nnkBracketExpr.newTree(
                            newIdentNode("typedesc"),
                            newIdentNode("CallType")
                            ),
                            newIdentNode("InitCall")
                        )
                    ),
                    nnkPragma.newTree(
                        newIdentNode("inline")
                    ),
                    newEmptyNode(),
                    nnkStmtList.newTree(
                        nnkWhenStmt.newTree(
                            nnkElifBranch.newTree(
                                nnkInfix.newTree(
                                    newIdentNode("is"),
                                    newIdentNode("ugen_call_type"),
                                    newIdentNode("InitCall")
                                ),
                                nnkStmtList.newTree(
                                    nnkPragma.newTree(
                                        nnkExprColonExpr.newTree(
                                            newIdentNode("fatal"),
                                            newLit("`Buffers` can only be accessed in the `perform` / `sample` blocks")
                                        )
                                    )
                                )
                            )
                        ),
                        statement_block
                    )
                )
            )
        
        elif statement_name == "setter":
            setter = nnkStmtList.newTree(
                nnkProcDef.newTree(
                    nnkPostfix.newTree(
                        newIdentNode("*"),
                        newIdentNode("setter")
                    ),
                    newEmptyNode(),
                    nnkGenericParams.newTree(
                        nnkIdentDefs.newTree(
                            newIdentNode("T"),
                            newIdentNode("SomeNumber"),
                            newEmptyNode()
                        )
                    ),
                    nnkFormalParams.newTree(
                        newIdentNode("void"),
                        nnkIdentDefs.newTree(
                            newIdentNode("buffer"),
                            newIdentNode("Buffer"),
                            newEmptyNode()
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("channel"),
                            newIdentNode("int"),
                            newLit(0)
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("index"),
                            newIdentNode("int"),
                            newLit(0)
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("x"),
                            newIdentNode("T"),
                            newEmptyNode()
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("ugen_call_type"),
                            nnkBracketExpr.newTree(
                            newIdentNode("typedesc"),
                            newIdentNode("CallType")
                            ),
                            newIdentNode("InitCall")
                        )
                    ),
                    nnkPragma.newTree(
                        newIdentNode("inline")
                    ),
                    newEmptyNode(),
                    nnkStmtList.newTree(
                        nnkWhenStmt.newTree(
                            nnkElifBranch.newTree(
                                nnkInfix.newTree(
                                    newIdentNode("is"),
                                    newIdentNode("ugen_call_type"),
                                    newIdentNode("InitCall")
                                ),
                                nnkStmtList.newTree(
                                    nnkPragma.newTree(
                                        nnkExprColonExpr.newTree(
                                            newIdentNode("fatal"),
                                            newLit("`Buffers` can only be accessed in the `perform` / `sample` blocks")
                                        )
                                    )
                                )
                            )
                        ),
                        statement_block
                    )
                )
            )

        else:
            error "Invalid block name: '" & statement_name & "'. Valid names are: 'obj', 'init', 'lockFromInput', 'lockFromParam', 'unlockBuffer', 'getter', 'setter'"

    if obj == nil:
        error "newBufferInterface: Missing `obj`"

    if init == nil:
        error "newBufferInterface: Missing `init`"

    if lockFromInput == nil:
        error "newBufferInterface: Missing `lockFromInput`"
        
    if lockFromParam == nil:
        error "newBufferInterface: Missing `lockFromParam`"
        
    if unlockBuffer == nil:
        error "newBufferInterface: Missing `unlockBuffer`"
        
    if getter == nil:
        error "newBufferInterface: Missing `getter`"
        
    if setter == nil:
        error "newBufferInterface: Missing `setter`"

    let otherStuff = nnkStmtList.newTree(
        nnkProcDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("read_inner")
            ),
            newEmptyNode(),
            nnkGenericParams.newTree(
                nnkIdentDefs.newTree(
                    newIdentNode("I"),
                    newIdentNode("SomeNumber"),
                    newEmptyNode()
                )
            ),
            nnkFormalParams.newTree(
                newIdentNode("float"),
                nnkIdentDefs.newTree(
                    newIdentNode("buffer"),
                    newIdentNode("Buffer"),
                    newEmptyNode()
                ),
                nnkIdentDefs.newTree(
                    newIdentNode("index"),
                    newIdentNode("I"),
                    newEmptyNode()
                ),
                nnkIdentDefs.newTree(
                    newIdentNode("ugen_call_type"),
                    nnkBracketExpr.newTree(
                        newIdentNode("typedesc"),
                        newIdentNode("CallType")
                    ),
                    newIdentNode("InitCall")
                )
            ),
            nnkPragma.newTree(
                newIdentNode("inline")
            ),
            newEmptyNode(),
            nnkStmtList.newTree(
                nnkWhenStmt.newTree(
                    nnkElifBranch.newTree(
                        nnkInfix.newTree(
                            newIdentNode("is"),
                            newIdentNode("ugen_call_type"),
                            newIdentNode("InitCall")
                        ),
                        nnkStmtList.newTree(
                            nnkPragma.newTree(
                                nnkExprColonExpr.newTree(
                                    newIdentNode("fatal"),
                                    newLit("`Buffers` can only be accessed in the `perform` / `sample` blocks")
                                )
                            )
                        )
                    )
                ),
                nnkLetSection.newTree(
                    nnkIdentDefs.newTree(
                        newIdentNode("buf_len"),
                        newEmptyNode(),
                        nnkDotExpr.newTree(
                            newIdentNode("buffer"),
                            newIdentNode("length")
                        )
                    )
                ),
                nnkIfStmt.newTree(
                    nnkElifBranch.newTree(
                        nnkInfix.newTree(
                            newIdentNode("<="),
                            newIdentNode("buf_len"),
                            newLit(0)
                        ),
                        nnkStmtList.newTree(
                            nnkReturnStmt.newTree(
                                newLit(0.0)
                            )
                        )
                    )
                ),
                nnkLetSection.newTree(
                    nnkIdentDefs.newTree(
                        newIdentNode("index_int"),
                        newEmptyNode(),
                        nnkCall.newTree(
                            newIdentNode("int"),
                            newIdentNode("index")
                        )
                    ),
                    nnkIdentDefs.newTree(
                        newIdentNode("index1"),
                        newIdentNode("int"),
                        nnkInfix.newTree(
                            newIdentNode("mod"),
                            newIdentNode("index_int"),
                            newIdentNode("buf_len")
                        )
                    ),
                    nnkIdentDefs.newTree(
                        newIdentNode("index2"),
                        newIdentNode("int"),
                        nnkInfix.newTree(
                            newIdentNode("mod"),
                            nnkPar.newTree(
                                nnkInfix.newTree(
                                    newIdentNode("+"),
                                    newIdentNode("index1"),
                                    newLit(1)
                                )
                            ),
                            newIdentNode("buf_len")
                        )
                    ),
                    nnkIdentDefs.newTree(
                        newIdentNode("frac"),
                        newIdentNode("float"),
                        nnkInfix.newTree(
                            newIdentNode("-"),
                            nnkCall.newTree(
                                newIdentNode("float"),
                                newIdentNode("index")
                            ),
                            nnkCall.newTree(
                                newIdentNode("float"),
                                newIdentNode("index_int")
                            )
                        )
                    )
                ),
                nnkReturnStmt.newTree(
                    nnkCall.newTree(
                    newIdentNode("float"),
                    nnkCall.newTree(
                        newIdentNode("linear_interp"),
                        newIdentNode("frac"),
                        nnkCall.newTree(
                        nnkDotExpr.newTree(
                            newIdentNode("buffer"),
                            newIdentNode("getter")
                        ),
                        newLit(0),
                        newIdentNode("index1"),
                        newIdentNode("ugen_call_type")
                        ),
                        nnkCall.newTree(
                        nnkDotExpr.newTree(
                            newIdentNode("buffer"),
                            newIdentNode("getter")
                        ),
                        newLit(0),
                        newIdentNode("index2"),
                        newIdentNode("ugen_call_type")
                        )
                    )
                    )
                )
            )
        ),
        nnkProcDef.newTree(
            nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode("read_inner")
            ),
            newEmptyNode(),
            nnkGenericParams.newTree(
            nnkIdentDefs.newTree(
                newIdentNode("I1"),
                newIdentNode("SomeNumber"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("I2"),
                newIdentNode("SomeNumber"),
                newEmptyNode()
            )
            ),
            nnkFormalParams.newTree(
            newIdentNode("float"),
            nnkIdentDefs.newTree(
                newIdentNode("buffer"),
                newIdentNode("Buffer"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("chan"),
                newIdentNode("I1"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("index"),
                newIdentNode("I2"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("ugen_call_type"),
                nnkBracketExpr.newTree(
                newIdentNode("typedesc"),
                newIdentNode("CallType")
                ),
                newIdentNode("InitCall")
            )
            ),
            nnkPragma.newTree(
            newIdentNode("inline")
            ),
            newEmptyNode(),
            nnkStmtList.newTree(
            nnkWhenStmt.newTree(
                nnkElifBranch.newTree(
                nnkInfix.newTree(
                    newIdentNode("is"),
                    newIdentNode("ugen_call_type"),
                    newIdentNode("InitCall")
                ),
                nnkStmtList.newTree(
                    nnkPragma.newTree(
                    nnkExprColonExpr.newTree(
                        newIdentNode("fatal"),
                        newLit("`Buffers` can only be accessed in the `perform` / `sample` blocks")
                    )
                    )
                )
                )
            ),
            nnkLetSection.newTree(
                nnkIdentDefs.newTree(
                newIdentNode("buf_len"),
                newEmptyNode(),
                nnkDotExpr.newTree(
                    newIdentNode("buffer"),
                    newIdentNode("length")
                )
                )
            ),
            nnkIfStmt.newTree(
                nnkElifBranch.newTree(
                nnkInfix.newTree(
                    newIdentNode("<="),
                    newIdentNode("buf_len"),
                    newLit(0)
                ),
                nnkStmtList.newTree(
                    nnkReturnStmt.newTree(
                    newLit(0.0)
                    )
                )
                )
            ),
            nnkLetSection.newTree(
                nnkIdentDefs.newTree(
                newIdentNode("chan_int"),
                newEmptyNode(),
                nnkCall.newTree(
                    newIdentNode("int"),
                    newIdentNode("chan")
                )
                ),
                nnkIdentDefs.newTree(
                newIdentNode("index_int"),
                newEmptyNode(),
                nnkCall.newTree(
                    newIdentNode("int"),
                    newIdentNode("index")
                )
                ),
                nnkIdentDefs.newTree(
                newIdentNode("index1"),
                newIdentNode("int"),
                nnkInfix.newTree(
                    newIdentNode("mod"),
                    newIdentNode("index_int"),
                    newIdentNode("buf_len")
                )
                ),
                nnkIdentDefs.newTree(
                newIdentNode("index2"),
                newIdentNode("int"),
                nnkInfix.newTree(
                    newIdentNode("mod"),
                    nnkPar.newTree(
                    nnkInfix.newTree(
                        newIdentNode("+"),
                        newIdentNode("index1"),
                        newLit(1)
                    )
                    ),
                    newIdentNode("buf_len")
                )
                ),
                nnkIdentDefs.newTree(
                newIdentNode("frac"),
                newIdentNode("float"),
                nnkInfix.newTree(
                    newIdentNode("-"),
                    nnkCall.newTree(
                    newIdentNode("float"),
                    newIdentNode("index")
                    ),
                    nnkCall.newTree(
                    newIdentNode("float"),
                    newIdentNode("index_int")
                    )
                )
                )
            ),
            nnkReturnStmt.newTree(
                nnkCall.newTree(
                newIdentNode("float"),
                nnkCall.newTree(
                    newIdentNode("linear_interp"),
                    newIdentNode("frac"),
                    nnkCall.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("buffer"),
                        newIdentNode("getter")
                    ),
                    newIdentNode("chan_int"),
                    newIdentNode("index1"),
                    newIdentNode("ugen_call_type")
                    ),
                    nnkCall.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("buffer"),
                        newIdentNode("getter")
                    ),
                    newIdentNode("chan_int"),
                    newIdentNode("index2"),
                    newIdentNode("ugen_call_type")
                    )
                )
                )
            )
            )
        ),
        nnkTemplateDef.newTree(
            nnkPostfix.newTree(
            newIdentNode("*"),
            nnkAccQuoted.newTree(
                newIdentNode("[]")
            )
            ),
            newEmptyNode(),
            nnkGenericParams.newTree(
            nnkIdentDefs.newTree(
                newIdentNode("I"),
                newIdentNode("SomeNumber"),
                newEmptyNode()
            )
            ),
            nnkFormalParams.newTree(
            newIdentNode("untyped"),
            nnkIdentDefs.newTree(
                newIdentNode("buffer"),
                newIdentNode("Buffer"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("i"),
                newIdentNode("I"),
                newEmptyNode()
            )
            ),
            nnkPragma.newTree(
            newIdentNode("dirty")
            ),
            newEmptyNode(),
            nnkStmtList.newTree(
            nnkCall.newTree(
                newIdentNode("getter"),
                newIdentNode("buffer"),
                newLit(0),
                nnkCall.newTree(
                newIdentNode("int"),
                newIdentNode("i")
                ),
                newIdentNode("ugen_call_type")
            )
            )
        ),
        nnkTemplateDef.newTree(
            nnkPostfix.newTree(
            newIdentNode("*"),
            nnkAccQuoted.newTree(
                newIdentNode("[]")
            )
            ),
            newEmptyNode(),
            nnkGenericParams.newTree(
            nnkIdentDefs.newTree(
                newIdentNode("I1"),
                newIdentNode("SomeNumber"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("I2"),
                newIdentNode("SomeNumber"),
                newEmptyNode()
            )
            ),
            nnkFormalParams.newTree(
            newIdentNode("untyped"),
            nnkIdentDefs.newTree(
                newIdentNode("buffer"),
                newIdentNode("Buffer"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("i1"),
                newIdentNode("I1"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("i2"),
                newIdentNode("I2"),
                newEmptyNode()
            )
            ),
            nnkPragma.newTree(
            newIdentNode("dirty")
            ),
            newEmptyNode(),
            nnkStmtList.newTree(
            nnkCall.newTree(
                newIdentNode("getter"),
                newIdentNode("buffer"),
                nnkCall.newTree(
                newIdentNode("int"),
                newIdentNode("i1")
                ),
                nnkCall.newTree(
                newIdentNode("int"),
                newIdentNode("i2")
                ),
                newIdentNode("ugen_call_type")
            )
            )
        ),
        nnkTemplateDef.newTree(
            nnkPostfix.newTree(
            newIdentNode("*"),
            nnkAccQuoted.newTree(
                newIdentNode("[]=")
            )
            ),
            newEmptyNode(),
            nnkGenericParams.newTree(
            nnkIdentDefs.newTree(
                newIdentNode("I"),
                newIdentNode("SomeNumber"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("S"),
                newIdentNode("SomeNumber"),
                newEmptyNode()
            )
            ),
            nnkFormalParams.newTree(
            newIdentNode("untyped"),
            nnkIdentDefs.newTree(
                newIdentNode("buffer"),
                newIdentNode("Buffer"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("i"),
                newIdentNode("I"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("x"),
                newIdentNode("S"),
                newEmptyNode()
            )
            ),
            nnkPragma.newTree(
            newIdentNode("dirty")
            ),
            newEmptyNode(),
            nnkStmtList.newTree(
            nnkCall.newTree(
                newIdentNode("setter"),
                newIdentNode("buffer"),
                newLit(0),
                nnkCall.newTree(
                newIdentNode("int"),
                newIdentNode("i")
                ),
                newIdentNode("x"),
                newIdentNode("ugen_call_type")
            )
            )
        ),
        nnkTemplateDef.newTree(
            nnkPostfix.newTree(
            newIdentNode("*"),
            nnkAccQuoted.newTree(
                newIdentNode("[]=")
            )
            ),
            newEmptyNode(),
            nnkGenericParams.newTree(
            nnkIdentDefs.newTree(
                newIdentNode("I1"),
                newIdentNode("SomeNumber"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("I2"),
                newIdentNode("SomeNumber"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("S"),
                newIdentNode("SomeNumber"),
                newEmptyNode()
            )
            ),
            nnkFormalParams.newTree(
            newIdentNode("untyped"),
            nnkIdentDefs.newTree(
                newIdentNode("buffer"),
                newIdentNode("Buffer"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("i1"),
                newIdentNode("I1"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("i2"),
                newIdentNode("I2"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("x"),
                newIdentNode("S"),
                newEmptyNode()
            )
            ),
            nnkPragma.newTree(
            newIdentNode("dirty")
            ),
            newEmptyNode(),
            nnkStmtList.newTree(
            nnkCall.newTree(
                newIdentNode("setter"),
                newIdentNode("buffer"),
                nnkCall.newTree(
                newIdentNode("int"),
                newIdentNode("i1")
                ),
                nnkCall.newTree(
                newIdentNode("int"),
                newIdentNode("i2")
                ),
                newIdentNode("x"),
                newIdentNode("ugen_call_type")
            )
            )
        ),
        nnkTemplateDef.newTree(
            nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode("read")
            ),
            newEmptyNode(),
            nnkGenericParams.newTree(
            nnkIdentDefs.newTree(
                newIdentNode("I"),
                newIdentNode("SomeNumber"),
                newEmptyNode()
            )
            ),
            nnkFormalParams.newTree(
            newIdentNode("untyped"),
            nnkIdentDefs.newTree(
                newIdentNode("buffer"),
                newIdentNode("Buffer"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("index"),
                newIdentNode("I"),
                newEmptyNode()
            )
            ),
            nnkPragma.newTree(
            newIdentNode("dirty")
            ),
            newEmptyNode(),
            nnkStmtList.newTree(
            nnkCall.newTree(
                newIdentNode("read_inner"),
                newIdentNode("buffer"),
                newIdentNode("index"),
                newIdentNode("ugen_call_type")
            )
            )
        ),
        nnkTemplateDef.newTree(
            nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode("read")
            ),
            newEmptyNode(),
            nnkGenericParams.newTree(
            nnkIdentDefs.newTree(
                newIdentNode("I1"),
                newIdentNode("SomeNumber"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("I2"),
                newIdentNode("SomeNumber"),
                newEmptyNode()
            )
            ),
            nnkFormalParams.newTree(
            newIdentNode("untyped"),
            nnkIdentDefs.newTree(
                newIdentNode("buffer"),
                newIdentNode("Buffer"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("chan"),
                newIdentNode("I1"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("index"),
                newIdentNode("I2"),
                newEmptyNode()
            )
            ),
            nnkPragma.newTree(
            newIdentNode("dirty")
            ),
            newEmptyNode(),
            nnkStmtList.newTree(
            nnkCall.newTree(
                newIdentNode("read_inner"),
                newIdentNode("buffer"),
                newIdentNode("chan"),
                newIdentNode("index"),
                newIdentNode("ugen_call_type")
            )
            )
        ),
        nnkProcDef.newTree(
            nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode("len")
            ),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
            newIdentNode("int"),
            nnkIdentDefs.newTree(
                newIdentNode("buffer"),
                newIdentNode("Buffer"),
                newEmptyNode()
            )
            ),
            nnkPragma.newTree(
            newIdentNode("inline")
            ),
            newEmptyNode(),
            nnkStmtList.newTree(
            nnkReturnStmt.newTree(
                nnkDotExpr.newTree(
                newIdentNode("buffer"),
                newIdentNode("length")
                )
            )
            )
        ),
        nnkProcDef.newTree(
            nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode("checkValidity")
            ),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
            newIdentNode("bool"),
            nnkIdentDefs.newTree(
                newIdentNode("obj"),
                newIdentNode("Buffer"),
                newEmptyNode()
            ),
            nnkIdentDefs.newTree(
                newIdentNode("ugen_auto_buffer"),
                nnkPtrTy.newTree(
                newIdentNode("OmniAutoMem")
                ),
                newEmptyNode()
            )
            ),
            newEmptyNode(),
            newEmptyNode(),
            nnkStmtList.newTree(
            nnkCall.newTree(
                nnkDotExpr.newTree(
                newIdentNode("ugen_auto_buffer"),
                newIdentNode("registerChild")
                ),
                nnkCast.newTree(
                newIdentNode("pointer"),
                newIdentNode("obj")
                )
            ),
            nnkReturnStmt.newTree(
                newIdentNode("true")
            )
            )
        )
    )

    result.add(
        obj,
        init,
        lockFromInput,
        lockFromParam,
        unlockBuffer,
        getter,
        setter,
        other_stuff
    )
