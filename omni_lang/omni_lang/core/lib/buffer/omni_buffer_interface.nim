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

#[
omniBufferInterface:
    struct:
    
    init:

    update:

    lock:

    unlock:

    getter:

    setter:
]#

proc declare_struct(statement_block : NimNode = nil) : NimNode {.compileTime.} =
    var 
        buffer_omni_struct_rec_list = nnkRecList.newTree()
        buffer_omni_struct = nnkTypeDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("Buffer_omni_struct")
            ),
            newEmptyNode(),
            nnkObjectTy.newTree(
                newEmptyNode(),
                nnkOfInherit.newTree(
                    newIdentNode("Buffer_inherit")
                ),
                buffer_omni_struct_rec_list
            )
        )
    
    if statement_block.len > 0:
        for entry in statement_block:
            assert entry.len == 2
            let ident_def = nnkIdentDefs.newTree(
                entry[0],
                entry[1][0],
                newEmptyNode()
            )
            
            buffer_omni_struct_rec_list.add(ident_def)
    else:
        buffer_omni_struct_rec_list = newEmptyNode()

    result = nnkStmtList.newTree(
        nnkTypeSection.newTree(
            buffer_omni_struct,
            nnkTypeDef.newTree(
                nnkPostfix.newTree(
                    newIdentNode("*"),
                    newIdentNode("Buffer")
                ),
                newEmptyNode(),
                nnkPtrTy.newTree(
                    newIdentNode("Buffer_omni_struct")
                )
            ),
            nnkTypeDef.newTree(
                nnkPostfix.newTree(
                    newIdentNode("*"),
                    newIdentNode("Buffer_omni_struct_ptr")
                ),
            newEmptyNode(),
            newIdentNode("Buffer")
            )
        )
    )

    error astGenRepr result

#This is quite an overhead
macro omniBufferInterface*(code_block : untyped) : untyped =
    if code_block.kind != nnkStmtList:
        error "omniBufferInterface: Invalid syntax. It must be a statement list."
    
    result = nnkStmtList.newTree()

    var 
        struct : NimNode
        init : NimNode
        update : NimNode
        lockBuffer : NimNode
        unlockBuffer : NimNode
        length : NimNode
        samplerate : NimNode
        channels : NimNode
        getter : NimNode
        setter : NimNode

    for statement in code_block:
        if statement.kind != nnkCall or statement.len > 2:
            error "omniBufferInterface: Invalid statement: '" & repr(statement) & "'. It must be a code block."

        let 
            statement_name = statement[0].strVal()
            statement_block = statement[1]

        if statement_name == "struct":
            struct = declare_struct(statement_block)

        elif statement_name == "init":
            if struct == nil:
                struct = declare_struct()

            var init_body = nnkStmtList.newTree(
                nnkWhenStmt.newTree(
                    nnkElifBranch.newTree(
                        nnkInfix.newTree(
                            newIdentNode("is"),
                            newIdentNode("omni_call_type"),
                            newIdentNode("Omni_PerformCall")
                        ),
                        nnkStmtList.newTree(
                            nnkPragma.newTree(
                                nnkExprColonExpr.newTree(
                                    newIdentNode("fatal"),
                                    newLit("Buffer: attempting to allocate memory in the 'perform' or 'sample' blocks")
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
                                        newIdentNode("Buffer_omni_struct")
                                    )
                                )
                            )
                        )
                    )
                ),
                nnkCall.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("omni_auto_mem"),
                        newIdentNode("omni_auto_mem_register_child")
                    ),
                    newIdentNode("buffer")
                ),
                nnkAsgn.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("buffer"),
                        newIdentNode("inputNum")
                    ),
                    nnkInfix.newTree(
                        newIdentNode("-"),
                        nnkCall.newTree(
                            newIdentNode("int"),
                            newIdentNode("inputNum")
                        ),
                        nnkCall.newTree(
                            newIdentNode("int"),
                            newLit(1)
                        )
                    )
                ),
                nnkIfStmt.newTree(
                    nnkElifBranch.newTree(
                        nnkInfix.newTree(
                            newIdentNode("<"),
                            nnkDotExpr.newTree(
                                newIdentNode("buffer"),
                                newIdentNode("inputNum")
                            ),
                            newLit(0)
                        ),
                        nnkStmtList.newTree(
                            nnkAsgn.newTree(
                                nnkDotExpr.newTree(
                                    newIdentNode("buffer"),
                                    newIdentNode("inputNum")
                                ),
                                newLit(0)
                            )
                        )
                    )
                ),
                nnkAsgn.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("buffer"),
                        newIdentNode("valid")
                    ),
                    newLit(false)
                ),
                statement_block,
                nnkReturnStmt.newTree(
                    newIdentNode("buffer")
                )
            )

            init = nnkStmtList.newTree(
                nnkProcDef.newTree(
                    nnkPostfix.newTree(
                        newIdentNode("*"),
                        newIdentNode("Buffer_omni_struct_new")
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
                            newIdentNode("inputNum"),
                            newIdentNode("S"),
                            newEmptyNode()
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("buffer_interface"),
                            newIdentNode("pointer"),
                            newEmptyNode()
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("omni_struct_type"),
                            nnkBracketExpr.newTree(
                                newIdentNode("typedesc"),
                                newIdentNode("Buffer_omni_struct_ptr")
                            ),
                            newEmptyNode()
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("omni_auto_mem"),
                            newIdentNode("Omni_AutoMem"),
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
                        newIdentNode("inline")
                    ),
                    newEmptyNode(),
                    init_body
                )
            )

        elif statement_name == "update":
            update = nnkStmtList.newTree(
                nnkProcDef.newTree(
                    nnkPostfix.newTree(
                        newIdentNode("*"),
                        newIdentNode("get_buffer_from_input")
                    ),
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("void"),
                        nnkIdentDefs.newTree(
                            newIdentNode("buffer"),
                            newIdentNode("Buffer"),
                            newEmptyNode()
                        ),
                        nnkIdentDefs.newTree(
                            newIdentNode("inputVal"),
                            newIdentNode("float"),
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

        elif statement_name == "lock":
            lockBuffer = nnkStmtList.newTree(
                nnkProcDef.newTree(
                    nnkPostfix.newTree(
                        newIdentNode("*"),
                        newIdentNode("omni_lock_buffer_from_wrapper")
                    ),
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("void"),
                        nnkIdentDefs.newTree(
                            newIdentNode("buffer"),
                            newIdentNode("Buffer"),
                            newEmptyNode()
                        ),
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

        elif statement_name == "length" or statement_name == "len":
            length = nnkStmtList.newTree(
                nnkTemplateDef.newTree(
                    newIdentNode("length"),
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("untyped"),
                        nnkIdentDefs.newTree(
                            newIdentNode("buffer"),
                            newIdentNode("Buffer"),
                            newEmptyNode()
                        )
                    ),
                    nnkPragma.newTree(
                        newIdentNode("dirty")
                    ),
                    newEmptyNode(),
                    statement_block
                ),
                nnkTemplateDef.newTree(
                    newIdentNode("len"),
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("untyped"),
                        nnkIdentDefs.newTree(
                            newIdentNode("buffer"),
                            newIdentNode("Buffer"),
                            newEmptyNode()
                        )
                    ),
                    nnkPragma.newTree(
                        newIdentNode("dirty")
                    ),
                    newEmptyNode(),
                    statement_block
                )
            )

        elif statement_name == "samplerate" or statement_name == "sampleRate":
            samplerate = nnkTemplateDef.newTree(
                newIdentNode("samplerate"),
                newEmptyNode(),
                newEmptyNode(),
                nnkFormalParams.newTree(
                    newIdentNode("untyped"),
                    nnkIdentDefs.newTree(
                        newIdentNode("buffer"),
                        newIdentNode("Buffer"),
                        newEmptyNode()
                    )
                ),
                nnkPragma.newTree(
                    newIdentNode("dirty")
                ),
                newEmptyNode(),
                statement_block
            )

        elif statement_name == "channels" or statement_name == "chans":
            channels = nnkStmtList.newTree(
                nnkTemplateDef.newTree(
                    newIdentNode("channels"),
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("untyped"),
                        nnkIdentDefs.newTree(
                            newIdentNode("buffer"),
                            newIdentNode("Buffer"),
                            newEmptyNode()
                        )
                    ),
                    nnkPragma.newTree(
                        newIdentNode("dirty")
                    ),
                    newEmptyNode(),
                    statement_block
                ),
                nnkTemplateDef.newTree(
                    newIdentNode("chans"),
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("untyped"),
                        nnkIdentDefs.newTree(
                            newIdentNode("buffer"),
                            newIdentNode("Buffer"),
                            newEmptyNode()
                        )
                    ),
                    nnkPragma.newTree(
                        newIdentNode("dirty")
                    ),
                    newEmptyNode(),
                    statement_block
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
                            newIdentNode("omni_call_type"),
                            nnkBracketExpr.newTree(
                            newIdentNode("typedesc"),
                            newIdentNode("Omni_CallType")
                            ),
                            newIdentNode("Omni_InitCall")
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
                            newIdentNode("omni_call_type"),
                            nnkBracketExpr.newTree(
                            newIdentNode("typedesc"),
                            newIdentNode("Omni_CallType")
                            ),
                            newIdentNode("Omni_InitCall")
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
                        statement_block
                    )
                )
            )

        else:
            error "omniBufferInterface: Invalid block name: '" & statement_name & "'. Valid names are: 'struct', 'init', 'lock', 'unlock', 'getter', 'setter'"

    if struct == nil:
        error "omniBufferInterface: Missing `struct`"

    if init == nil:
        error "omniBufferInterface: Missing `init`"

    if update == nil:
        error "omniBufferInterface: Missing `update`"
    
    if lockBuffer == nil:
        error "omniBufferInterface: Missing `lock`"

    if unlockBuffer == nil:
        error "omniBufferInterface: Missing `unlock`"

    #[
    if length == nil:
        error "omniBufferInterface: Missing `length`"

    if samplerate == nil:
        error "omniBufferInterface: Missing `samplerate`"

    if channels == nil:
        error "omniBufferInterface: Missing `channels`"
    ]#
        
    if getter == nil:
        error "omniBufferInterface: Missing `getter`"
        
    if setter == nil:
        error "omniBufferInterface: Missing `setter`"

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
            
            return float(linear_interp(frac, buffer.getter(0, index1, omni_call_type), buffer.getter(0, index2, omni_call_type)))

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
            
            return float(linear_interp(frac, buffer.getter(chan_int, index1, omni_call_type), buffer.getter(chan_int, index2, omni_call_type)))
    ]#
    let omni_read_value_buffer = nnkStmtList.newTree(
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
            newIdentNode("inline")
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
                    newIdentNode("omni_call_type")
                    ),
                    nnkCall.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("buffer"),
                        newIdentNode("getter")
                    ),
                    newLit(0),
                    newIdentNode("index2"),
                    newIdentNode("omni_call_type")
                    )
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
            newIdentNode("inline")
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
                    newIdentNode("omni_call_type")
                    ),
                    nnkCall.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("buffer"),
                        newIdentNode("getter")
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
        )

    let size = nnkTemplateDef.newTree(
        newIdentNode("size"),
        newEmptyNode(),
        newEmptyNode(),
        nnkFormalParams.newTree(
            newIdentNode("untyped"),
            nnkIdentDefs.newTree(
                newIdentNode("buffer"),
                newIdentNode("Buffer"),
                newEmptyNode()
            )
        ),
        nnkPragma.newTree(
            newIdentNode("dirty")
        ),
        newEmptyNode(),
        nnkStmtList.newTree(
            nnkInfix.newTree(
                newIdentNode("*"),
                nnkCall.newTree(
                    newIdentNode("length"),
                    newIdentNode("buffer")
                ),
                nnkCall.newTree(
                    newIdentNode("channels"),
                    newIdentNode("buffer")
                )
            )
        )
    )

    result.add(
        struct,
        init,
        update,
        lockBuffer,
        unlockBuffer,
        #[ length,
        samplerate,
        channels,
        size, ]#
        getter,
        setter,
        omni_read_value_buffer
    )