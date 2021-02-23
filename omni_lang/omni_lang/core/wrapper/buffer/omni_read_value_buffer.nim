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

#[
proc omni_read_value_buffer*[I : SomeNumber](buffer : Buffer, index : I, omni_call_type : typedesc[Omni_CallType] = Omni_InitCall) : float {.inline.} =
    when omni_call_type is Omni_InitCall:
        {.fatal: "'Buffers' can only be accessed in the 'perform' / 'sample' blocks".}

    let buf_len = buffer.length
    
    if buf_len <= 0:
        return 0.0

    let
        index_int = int(index)
        index1 : int = index_int mod buf_len
        index2 : int = (index1 + 1) mod buf_len
        frac : float  = float(index) - float(index_int)
    
    return float(linear_interp(frac, buffer.omni_get_value_buffer(0, index1, omni_call_type), buffer.omni_get_value_buffer(0, index2, omni_call_type)))

#linear interp read (more than 1 channel) (i1 == channel, i2 == index)
proc omni_read_value_buffer*[I1 : SomeNumber, I2 : SomeNumber](buffer : Buffer, chan : I1, index : I2, omni_call_type : typedesc[Omni_CallType] = Omni_InitCall) : float {.inline.} =
    when omni_call_type is Omni_InitCall:
        {.fatal: "'Buffers' can only be accessed in the 'perform' / 'sample' blocks".}

    let buf_len = buffer.length

    if buf_len <= 0:
        return 0.0
    
    let 
        chan_int = int(chan)
        index_int = int(index)
        index1 : int = index_int mod buf_len
        index2 : int = (index1 + 1) mod buf_len
        frac : float  = float(index) - float(index_int)
    
    return float(linear_interp(frac, buffer.omni_get_value_buffer(chan_int, index1, omni_call_type), buffer.omni_get_value_buffer(chan_int, index2, omni_call_type)))
]#
template omni_read_value_buffer*() : untyped {.dirty.} =
    nnkStmtList.newTree(
        nnkProcDef.newTree(
            nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode("omni_read_value_buffer")
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
                newIdentNode("omni_call_type"),
                nnkBracketExpr.newTree(
                newIdentNode("typedesc"),
                newIdentNode("Omni_CallType")
                ),
                newIdentNode("Omni_InitCall")
            )
            ),
            nnkPragma.newTree(
            newIdentNode("inline"),
            newIdentNode("noSideEffect"),
            nnkExprColonExpr.newTree(
                newIdentNode("raises"),
                nnkBracket.newTree()
            )
            ),
            newEmptyNode(),
            nnkStmtList.newTree(
            nnkWhenStmt.newTree(
                nnkElifBranch.newTree(
                nnkInfix.newTree(
                    newIdentNode("is"),
                    newIdentNode("omni_call_type"),
                    newIdentNode("Omni_InitCall")
                ),
                nnkStmtList.newTree(
                    nnkPragma.newTree(
                    nnkExprColonExpr.newTree(
                        newIdentNode("fatal"),
                        newLit("'Buffers' can only be accessed in the 'perform' / 'sample' blocks")
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
                    newFloatLitNode(0.0)
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
                    newIdentNode("linear_interp"),
                    newIdentNode("frac"),
                    nnkCall.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("buffer"),
                        newIdentNode("omni_get_value_buffer")
                    ),
                    newLit(0),
                    newIdentNode("index1"),
                    newIdentNode("omni_call_type")
                    ),
                    nnkCall.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("buffer"),
                        newIdentNode("omni_get_value_buffer")
                    ),
                    newLit(0),
                    newIdentNode("index2"),
                    newIdentNode("omni_call_type")
                    )
                )
            )
            )
        ),
        nnkProcDef.newTree(
            nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode("omni_read_value_buffer")
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
                newIdentNode("omni_call_type"),
                nnkBracketExpr.newTree(
                newIdentNode("typedesc"),
                newIdentNode("Omni_CallType")
                ),
                newIdentNode("Omni_InitCall")
            )
            ),
            nnkPragma.newTree(
            newIdentNode("inline"),
            newIdentNode("noSideEffect"),
            nnkExprColonExpr.newTree(
                newIdentNode("raises"),
                nnkBracket.newTree()
            )
            ),
            newEmptyNode(),
            nnkStmtList.newTree(
            nnkWhenStmt.newTree(
                nnkElifBranch.newTree(
                nnkInfix.newTree(
                    newIdentNode("is"),
                    newIdentNode("omni_call_type"),
                    newIdentNode("Omni_InitCall")
                ),
                nnkStmtList.newTree(
                    nnkPragma.newTree(
                    nnkExprColonExpr.newTree(
                        newIdentNode("fatal"),
                        newLit("'Buffers' can only be accessed in the 'perform' / 'sample' blocks")
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
                    newFloatLitNode(0.0)
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
                    newIdentNode("linear_interp"),
                    newIdentNode("frac"),
                    nnkCall.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("buffer"),
                        newIdentNode("omni_get_value_buffer")
                    ),
                    newIdentNode("chan_int"),
                    newIdentNode("index1"),
                    newIdentNode("omni_call_type")
                    ),
                    nnkCall.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("buffer"),
                        newIdentNode("omni_get_value_buffer")
                    ),
                    newIdentNode("chan_int"),
                    newIdentNode("index2"),
                    newIdentNode("omni_call_type")
                    )
                )
            )
            )
        )
        )