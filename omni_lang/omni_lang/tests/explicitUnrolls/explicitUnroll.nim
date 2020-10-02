import strutils, macros

proc find_all(statement : NimNode, what : NimNode, with : NimNode) : void {.compileTime.} =
    for i, entry in statement:
        if entry.kind == nnkSym or entry.kind == nnkIdent:
            let new_ident = newIdentNode(entry.strVal())
            if new_ident == what:
                statement[i] = with
            
            #convert all syms to ident anyway
            else:
                statement[i] = new_ident

        #num already checked
        if entry.kind == nnkCall:
            if entry[0].strVal().startsWith("generate_"):
                entry.add(
                    newLit(true)
                )

        find_all(entry, what, with)

######
# ye #
######

#Only works with auto params...  
proc ye_inner(a : auto = 0) =
    echo a

macro generate_ye_loops(proc_name : typed, var_name_str : typed, num : typed, num_already_checked : typed = false) =
    let num_already_checked_bool = num_already_checked.boolVal()
    
    let num_kind = num.kind

    if (num_kind != nnkInt64Lit and num_kind != nnkInt32Lit and num_kind != nnkIntLit) and not num_already_checked_bool:
        error "'" & repr(num) & "' must be string lit"

    let 
        var_name = newIdentNode(var_name_str.strVal())
        num_val = num.intVal()
        num_lit = newLit(num_val)

    let old_proc = proc_name.getImpl()
    
    var new_proc = old_proc.copy()

    let new_proc_name = newIdentNode(proc_name.strVal() & "_" & $num_val)
    
    new_proc[0] = new_proc_name

    #Sub every a with the num
    find_all(new_proc[^1], var_name, num_lit)

    #error repr new_proc

    #typed to untyped
    new_proc = parseStmt(repr(new_proc))
    
    result = nnkStmtList.newTree(
        new_proc,
        nnkCall.newTree(
            new_proc_name,
            num
        )
    )

template ye(a) =
    generate_ye_loops(ye_inner, "a", a)

######
# ya #
######

#Only works with auto params...        
proc ya_inner(a : auto = 0) =
    ye(a)

macro generate_ya_loops(proc_name : typed, var_name_str : typed, num : typed, num_already_checked : typed = false) =
    let num_already_checked_bool = num_already_checked.boolVal()
    
    let num_kind = num.kind

    if (num_kind != nnkInt64Lit and num_kind != nnkInt32Lit and num_kind != nnkIntLit) and not num_already_checked_bool:
        error "'" & repr(num) & "' must be string lit"

    let 
        var_name = newIdentNode(var_name_str.strVal())
        num_val = num.intVal()
        num_lit = newLit(num_val)

    let old_proc = proc_name.getImpl()
    
    var new_proc = old_proc.copy()

    let new_proc_name = newIdentNode(proc_name.strVal() & "_" & $num_val)
    
    new_proc[0] = new_proc_name

    #Sub every a with the num
    find_all(new_proc[^1], var_name, num_lit)

    #error repr new_proc

    #typed to untyped
    new_proc = parseStmt(repr(new_proc))
    
    result = nnkStmtList.newTree(
        new_proc,
        nnkCall.newTree(
            new_proc_name,
            num
        )
    )

template ya(a) =
    generate_ya_loops(ya_inner, "a", a)


######
# yu #
######

#Only works with auto params...
proc yu_inner(a : auto = 0) =
    ya(a)

macro generate_yu_loops(proc_name : typed, var_name_str : typed, num : typed, num_already_checked : typed = false) =
    let num_already_checked_bool = num_already_checked.boolVal()
    
    let num_kind = num.kind

    if (num_kind != nnkInt64Lit and num_kind != nnkInt32Lit and num_kind != nnkIntLit) and not num_already_checked_bool:
        error "'" & repr(num) & "' must be string lit"

    let 
        var_name = newIdentNode(var_name_str.strVal())
        num_val = num.intVal()
        num_lit = newLit(num_val)

    let old_proc = proc_name.getImpl()
    
    var new_proc = old_proc.copy()

    let new_proc_name = newIdentNode(proc_name.strVal() & "_" & $num_val)
    
    new_proc[0] = new_proc_name

    #Sub every a with the num
    find_all(new_proc[^1], var_name, num_lit)

    #error repr new_proc

    #typed to untyped
    new_proc = parseStmt(repr(new_proc))
    
    result = nnkStmtList.newTree(
        new_proc,
        nnkCall.newTree(
            new_proc_name,
            num
        )
    )

    #error repr result

template yu(a) =
    generate_yu_loops(yu_inner, "a", a)


expandMacros:
    yu 10
    yu 100