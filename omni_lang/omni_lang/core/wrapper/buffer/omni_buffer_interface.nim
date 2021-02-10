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

import omni_read_value_buffer, macros

proc declare_struct(statement_block : NimNode = nil) : NimNode {.inline, compileTime.} =
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
    
    if statement_block.len == 1:
        if statement_block[0].kind == nnkDiscardStmt:
            buffer_omni_struct_rec_list = newEmptyNode()
    elif statement_block.len > 0:
        for entry in statement_block:
            assert entry.len == 2
            let ident_def = nnkIdentDefs.newTree(
                nnkPostfix.newTree(
                    newIdentNode("*"),
                    entry[0]
                ),
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

    #error astGenRepr result

template when_not_perform() : untyped {.dirty.} = 
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
    )

proc declare_proc(name : string, statement_block : NimNode, return_type : string = "void", add_perform_check : bool = true, is_lock : bool = false, is_unlock : bool = false) : NimNode {.inline, compileTime.} =        
    var 
        args = nnkFormalParams.newTree(
            newIdentNode(return_type),
            nnkIdentDefs.newTree(
                newIdentNode("buffer"),
                newIdentNode("Buffer"),
                newEmptyNode()
            )  
        )

        stmt_list = nnkStmtList.newTree()

    if add_perform_check:
        args.add(
            nnkIdentDefs.newTree(
                newIdentNode("omni_call_type"),
                nnkBracketExpr.newTree(
                    newIdentNode("typedesc"),
                    newIdentNode("Omni_CallType")
                ),
                newIdentNode("Omni_InitCall")
            )
        )

        stmt_list.add(
            when_not_perform()
        )

    if not is_unlock:
        stmt_list.add(
            statement_block
        )
    else:
        stmt_list.add(
            nnkIfStmt.newTree(
                nnkElifBranch.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("buffer"),
                        newIdentNode("valid_lock")
                    ),
                    nnkStmtList.newTree(
                        statement_block
                    )
                )
            )
        )

    if is_lock:
        return nnkProcDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("omni_lock_buffer")
            ),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("bool"),
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
                nnkProcDef.newTree(
                    newIdentNode("omni_lock_buffer_inner"),
                    newEmptyNode(),
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("bool"),
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
                    stmt_list
                ),
                nnkLetSection.newTree(
                    nnkIdentDefs.newTree(
                        newIdentNode("valid_lock"),
                        newEmptyNode(),
                        nnkCall.newTree(
                            newIdentNode("omni_lock_buffer_inner"),
                            newIdentNode("buffer")
                        )
                    )
                ),
                nnkAsgn.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("buffer"),
                        newIdentNode("valid_lock")
                    ),
                    newIdentNode("valid_lock")
                ),
                nnkReturnStmt.newTree(
                    newIdentNode("valid_lock")
                )
            )
        )

    return nnkProcDef.newTree(
        nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode(name)
        ),
        newEmptyNode(),
        newEmptyNode(),
        args,
        nnkPragma.newTree(
            newIdentNode("inline")
        ),
        newEmptyNode(),
        stmt_list
    )

#This is quite an overhead
macro omniBufferInterface*(code_block : untyped) : untyped =
    if code_block.kind != nnkStmtList:
        error "omniBufferInterface: Invalid syntax. It must be a statement list."
    
    result = nnkStmtList.newTree()

    var 
        debug  = false
        struct : NimNode
        init : NimNode
        update : NimNode
        lock : NimNode
        unlock : NimNode
        #[ length : NimNode
        samplerate : NimNode
        channels : NimNode ]#
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
                                newIdentNode("omni_alloc0"),
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
                        newIdentNode("valid")
                    ),
                    newLit(false)
                ),
                nnkAsgn.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("buffer"),
                        newIdentNode("name"),
                    ),
                    newIdentNode("buffer_name")
                ),
                statement_block,
                nnkAsgn.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("buffer"),
                        newIdentNode("init"),
                    ),
                    newLit(true)
                ),
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
                    newEmptyNode(),
                    nnkFormalParams.newTree(
                        newIdentNode("Buffer"),
                        nnkIdentDefs.newTree(
                            newIdentNode("buffer_name"),
                            newIdentNode("string"),
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
                        newIdentNode("omni_update_buffer")
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
                            newIdentNode("val"),
                            newIdentNode("cstring"),
                            newLit("")
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
            lock = declare_proc("omni_lock_buffer", statement_block, "bool", false, is_lock=true)
        
        elif statement_name == "unlock":
            unlock = declare_proc("omni_unlock_buffer", statement_block, "void", false, is_unlock=true)

        #[ elif statement_name == "length" or statement_name == "len":
            length = declare_proc("omni_get_length_buffer", statement_block, "int")
                
        elif statement_name == "samplerate" or statement_name == "sampleRate":
            samplerate = declare_proc("omni_get_samplerate_buffer", statement_block, "float")

        elif statement_name == "channels" or statement_name == "chans":
            channels = declare_proc("omni_get_channels_buffer", statement_block, "int") ]#
        
        elif statement_name == "getter":
            getter = nnkStmtList.newTree(
                nnkProcDef.newTree(
                    nnkPostfix.newTree(
                        newIdentNode("*"),
                        newIdentNode("omni_get_value_buffer")
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
                        when_not_perform(),
                        statement_block
                    )
                )
            )
        
        elif statement_name == "setter":
            setter = nnkStmtList.newTree(
                nnkProcDef.newTree(
                    nnkPostfix.newTree(
                        newIdentNode("*"),
                        newIdentNode("omni_set_value_buffer")
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
                        when_not_perform(),
                        statement_block
                    )
                )
            )

        elif statement_name == "debug":
            if statement_block.len == 1:
                let true_or_false = statement_block[0]
                if true_or_false.kind == nnkIdent:
                    if true_or_false.strVal == "true":
                        debug = true
                else:
                    error "omniBufferInterface: 'debug' must be a single ident, 'true' or 'false'."
            else:
                error "omniBufferInterface: 'debug' must be a single ident, 'true' or 'false'."
        else:
            error "omniBufferInterface: Invalid block name: '" & statement_name & "'. Valid names are: 'struct', 'init', 'update', 'lock', 'unlock', 'getter', 'setter'"

    if struct == nil:
        error "omniBufferInterface: Missing 'struct'"

    if init == nil:
        error "omniBufferInterface: Missing 'init'"

    if update == nil:
        error "omniBufferInterface: Missing 'update'"
    
    if lock == nil:
        error "omniBufferInterface: Missing 'lock'"

    if unlock == nil:
        error "omniBufferInterface: Missing 'unlock'"
    
    #[ if length == nil:
        error "omniBufferInterface: Missing 'length'"

    if samplerate == nil:
        error "omniBufferInterface: Missing 'samplerate'"

    if channels == nil:
        error "omniBufferInterface: Missing 'channels'" ]#
        
    if getter == nil:
        error "omniBufferInterface: Missing 'getter'"
        
    if setter == nil:
        error "omniBufferInterface: Missing 'setter'"

    let omni_read_value_buffer = omni_read_value_buffer()

    result.add(
        struct,
        init,
        update,
        lock,
        unlock,
        #[ length,
        samplerate,
        channels, ]#
        getter,
        setter,
        omni_read_value_buffer
    )

    #To be copy / pasted once an interface has been generated
    if debug:
        error repr result