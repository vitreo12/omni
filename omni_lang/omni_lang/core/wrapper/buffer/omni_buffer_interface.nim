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

import omni_read_value_buffer, macros

proc declare_local_setter_proc(field_name : string, field_type : string) : NimNode {.inline, compileTime.} =
    let field_name_ident = newIdentNode(field_name)
    return nnkTemplateDef.newTree(
        nnkAccQuoted.newTree(
            field_name_ident,
            newIdentNode("=")
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
                field_name_ident,
                newIdentNode(field_type),
                newEmptyNode()
            )
        ),
        nnkPragma.newTree(
            newIdentNode("dirty")
        ),
        newEmptyNode(),
        nnkStmtList.newTree(
            nnkCall.newTree(
                newIdentNode("omni_set_" & field_name & "_buffer"),
                newIdentNode("buffer"),
                field_name_ident
            )
        )
    )

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

        buffer_setter_procs = nnkStmtList.newTree(
            #declare_local_setter_proc("name", "string"), #name is not neeeded
            declare_local_setter_proc("valid_lock", "bool"),
            #These are exported directly cause they cause problems with normal "samplerate" meaning
            #declare_local_setter_proc("length", "int"),
            #declare_local_setter_proc("samplerate", "float"),
            #declare_local_setter_proc("channels", "int"),
        )
    
    if statement_block.len == 1:
        if statement_block[0].kind == nnkDiscardStmt:
            buffer_omni_struct_rec_list = newEmptyNode()
    elif statement_block.len > 0:
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
        ),
        buffer_setter_procs
    )

    #error repr result
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

proc declare_lock_unlock_proc(statement_block : NimNode, is_lock : bool = false) : NimNode {.inline, compileTime.} =        
    var 
        args = nnkFormalParams.newTree()
        stmt_list = nnkStmtList.newTree()

    if is_lock:
        args.add(
            newIdentNode("bool"),
            nnkIdentDefs.newTree(
                newIdentNode("buffer"),
                newIdentNode("Buffer"),
                newEmptyNode()
            )  
        )
        
        stmt_list.add(
            statement_block
        )

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
                newIdentNode("inline"),
                newIdentNode("noSideEffect"),
                nnkExprColonExpr.newTree(
                    newIdentNode("raises"),
                    nnkBracket.newTree()
                )
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
                        newIdentNode("inline"),
                        newIdentNode("noSideEffect"),
                        nnkExprColonExpr.newTree(
                            newIdentNode("raises"),
                            nnkBracket.newTree()
                        )
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
    else:
        args.add(
            newIdentNode("void"),
            nnkIdentDefs.newTree(
                newIdentNode("buffer"),
                newIdentNode("Buffer"),
                newEmptyNode()
            )  
        )

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

        return nnkProcDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("omni_unlock_buffer")
            ),
            newEmptyNode(),
            newEmptyNode(),
            args,
            nnkPragma.newTree(
                newIdentNode("inline"),
                newIdentNode("noSideEffect"),
                nnkExprColonExpr.newTree(
                    newIdentNode("raises"),
                    nnkBracket.newTree()
                )
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
        getter : NimNode
        setter : NimNode
        extra : NimNode

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
                                    newLit("struct 'Buffer': attempting to allocate memory in the 'perform' or 'sample' blocks.")
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
                                    newIdentNode("sizeof"),
                                    newIdentNode("Buffer_omni_struct")
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
                        newIdentNode("name"),
                    ),
                    newIdentNode("buffer_name")
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
                        newIdentNode("inline"),
                        newIdentNode("noSideEffect"),
                        nnkExprColonExpr.newTree(
                            newIdentNode("raises"),
                            nnkBracket.newTree()
                        )
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
                            newIdentNode("value"),
                            newIdentNode("cstring"),
                            newLit("")
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
                        statement_block
                    )
                )
            )

        elif statement_name == "lock":
            lock = declare_lock_unlock_proc(statement_block, is_lock=true)
        
        elif statement_name == "unlock":
            unlock = declare_lock_unlock_proc(statement_block)
        
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
                        newIdentNode("inline"),
                        newIdentNode("noSideEffect"),
                        nnkExprColonExpr.newTree(
                            newIdentNode("raises"),
                            nnkBracket.newTree()
                        )
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
                        newIdentNode("inline"),
                        newIdentNode("noSideEffect"),
                        nnkExprColonExpr.newTree(
                            newIdentNode("raises"),
                            nnkBracket.newTree()
                        )
                    ),
                    newEmptyNode(),
                    nnkStmtList.newTree(
                        when_not_perform(),
                        statement_block
                    )
                )
            )

        elif statement_name == "extra":
            extra = nnkStmtList.newTree(
                statement_block
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
        getter,
        setter,
        omni_read_value_buffer
    )

    if extra != nil:
        result.add(
            extra
        )

    #To be copy / pasted once an interface has been generated
    if debug:
        error repr result
