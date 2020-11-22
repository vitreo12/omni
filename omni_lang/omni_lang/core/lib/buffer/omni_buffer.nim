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

type
    Buffer_inherit* = object of RootObj
        inputNum*  : int      #in interface
        name*      : cstring  #param interface
        valid*     : bool     #buffer validity

        length*     : int
        channels*   : int
        samplerate* : float

    #Don't export these
    Buffer = ptr Buffer_inherit
    Buffer_struct_export = Buffer

#1 channel
template `[]`*[I : SomeNumber](buffer : Buffer, i : I) : untyped {.dirty.} =
    getter(buffer, 0, int(i), ugen_call_type)
    
#more than 1 channel (i1 == channel, i2 == index)
template `[]`*[I1 : SomeNumber, I2 : SomeNumber](buffer : Buffer, i1 : I1, i2 : I2) : untyped {.dirty.} =
    getter(buffer, int(i1), int(i2), ugen_call_type)

#1 channel
template `[]=`*[I : SomeNumber, S : SomeNumber](buffer : Buffer, i : I, x : S) : untyped {.dirty.} =
    setter(buffer, 0, int(i), x, ugen_call_type)

#more than 1 channel (i1 == channel, i2 == index)
template `[]=`*[I1 : SomeNumber, I2 : SomeNumber, S : SomeNumber](buffer : Buffer, i1 : I1, i2 : I2, x : S) : untyped {.dirty.} =
    setter(buffer, int(i1), int(i2), x, ugen_call_type)

#interp read
template read*[I : SomeNumber](buffer : Buffer, index : I) : untyped {.dirty.} =
    read_inner(buffer, index, ugen_call_type)

#interp read
template read*[I1 : SomeNumber, I2 : SomeNumber](buffer : Buffer, chan : I1, index : I2) : untyped {.dirty.} =
    read_inner(buffer, chan, index, ugen_call_type)

#Alias for length
template len*(buffer : Buffer) : untyped {.dirty.} =
    buffer.length

#Alias for chans
template chans*(buffer : Buffer) : untyped {.dirty.} =
    buffer.channels

#Chans * length = size
proc size*(buffer : Buffer) : int {.inline.} =
    return buffer.channels * buffer.length

#Internal checking for structs. It works fine without redefining it for every newBufferInterface!
proc checkValidity*(obj : Buffer) : bool =
    return true

#This is quite an overhead, as it gets compiled even when not using Buffer. Find a way to not compile it in that case.
macro newBufferInterface*(code_block : untyped) : untyped =
    if code_block.kind != nnkStmtList:
        error "Invalid syntax for newBufferInterface. It must be a statement list."
    
    result = nnkStmtList.newTree()

    var 
        obj : NimNode
        init : NimNode
        getFromInput : NimNode
        getFromParam : NimNode
        lockBuffer : NimNode
        unlockBuffer : NimNode
        length : NimNode
        samplerate : NimNode
        channels : NimNode
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
                                    newLit("attempting to allocate memory in the 'perform' or 'sample' blocks for `struct Buffer`")
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

        elif statement_name == "getFromInput" or statement_name == "get_from_input":
            getFromInput = nnkStmtList.newTree(
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

        elif statement_name == "getFromParam" or statement_name == "get_from_param":
            getFromParam = nnkStmtList.newTree(
                nnkDiscardStmt.newTree(
                    newEmptyNode()
                )
            )

        elif statement_name == "lock":
            lockBuffer = nnkStmtList.newTree(
                nnkProcDef.newTree(
                    nnkPostfix.newTree(
                        newIdentNode("*"),
                        newIdentNode("lock_buffer")
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
            error "Invalid block name: '" & statement_name & "'. Valid names are: 'obj', 'init', 'lockBuffer', 'getFromParam', 'unlockBuffer', 'getter', 'setter'"

    if obj == nil:
        error "newBufferInterface: Missing `obj`"

    if init == nil:
        error "newBufferInterface: Missing `init`"

    if getFromInput == nil:
        error "newBufferInterface: Missing `getFromInput`"
        
    if getFromParam == nil:
        error "newBufferInterface: Missing `getFromParam`"
    
    if lockBuffer == nil:
        error "newBufferInterface: Missing `lock`"

    if unlockBuffer == nil:
        error "newBufferInterface: Missing `unlock`"

    #[
    if length == nil:
        error "newBufferInterface: Missing `length`"

    if samplerate == nil:
        error "newBufferInterface: Missing `samplerate`"

    if channels == nil:
        error "newBufferInterface: Missing `channels`"
    ]#
        
    if getter == nil:
        error "newBufferInterface: Missing `getter`"
        
    if setter == nil:
        error "newBufferInterface: Missing `setter`"

    #[
        proc read_inner*[I : SomeNumber](buffer : Buffer, index : I, ugen_call_type : typedesc[CallType] = InitCall) : float {.inline.} =
            when ugen_call_type is InitCall:
                {.fatal: "'Buffers' can only be accessed in the 'perform' / 'sample' blocks".}

            let buf_len = buffer.length
            
            if buf_len <= 0:
                return 0.0

            let
                index_int = int(index)
                index1 : int = index_int mod buf_len
                index2 : int = (index1 + 1) mod buf_len
                frac : float  = float(index) - float(index_int)
            
            return float(linear_interp(frac, buffer.getter(0, index1, ugen_call_type), buffer.getter(0, index2, ugen_call_type)))

        #linear interp read (more than 1 channel) (i1 == channel, i2 == index)
        proc read_inner*[I1 : SomeNumber, I2 : SomeNumber](buffer : Buffer, chan : I1, index : I2, ugen_call_type : typedesc[CallType] = InitCall) : float {.inline.} =
            when ugen_call_type is InitCall:
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
            
            return float(linear_interp(frac, buffer.getter(chan_int, index1, ugen_call_type), buffer.getter(chan_int, index2, ugen_call_type)))
    ]#
    let read_inner = nnkStmtList.newTree(
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
        obj,
        init,
        getFromInput,
        getFromParam,
        lockBuffer,
        unlockBuffer,
        #[
        length,
        samplerate,
        channels,
        size,
        ]#
        getter,
        setter,
        read_inner
    )