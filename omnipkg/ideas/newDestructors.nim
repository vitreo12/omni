import macros
import tables

var destructors_array {.compileTime.} = initTable[string, NimNode]()

macro defineDestructor*(obj : typed, ptr_name : untyped, generics : untyped, ptr_bracket_expr : untyped, var_names : untyped, is_ugen_destructor : bool, is_inst_destructor : bool, types_inst : untyped) =
    var 
        final_stmt    = nnkStmtList.newTree()
        proc_def      : NimNode
        formal_params = nnkFormalParams.newTree(newIdentNode("void"))
        proc_body     = nnkStmtList.newTree()
        
        rec_list : NimNode

        var_obj_positions : seq[int]
        ptr_name_str      : string
        
    let 
        is_ugen_destructor_bool = is_ugen_destructor.boolVal()
        is_inst_destructor_bool = is_inst_destructor.boolVal()

    if is_ugen_destructor_bool == true:
        #Full proc definition for OmniDestructor. The result is: proc OmniDestructor*(ugen : ptr UGen) : void {.exportc: "OmniDestructor".} 
        proc_def = nnkProcDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("OmniDestructor")
            ),
            newEmptyNode(),
            newEmptyNode(),
            nnkFormalParams.newTree(
                newIdentNode("void"),
                nnkIdentDefs.newTree(
                    newIdentNode("obj"),
                nnkPtrTy.newTree(
                    newIdentNode("UGen")
                ),
                newEmptyNode()
                )
            ),
            nnkPragma.newTree(
                nnkExprColonExpr.newTree(
                    newIdentNode("exportc"),
                    newLit("OmniDestructor")
                )
            ),
            newEmptyNode()
        )
    else:
        #Just add proc destructor to proc def. Everything else will be added later
        proc_def = nnkProcDef.newTree(
            nnkPostfix.newTree(
                newIdentNode("*"),
                newIdentNode("destructor")
            ),
            newEmptyNode(),
        )

        #Actual name
        ptr_name_str = ptr_name.strVal()
    
    if is_inst_destructor_bool == true:
        echo "ah"
    else:
        rec_list = getImpl(obj)[2][2]
    
    #Extract if there is a ptr SomeObject_obj in the fields of the type, to add it to destructor procedure.
    for index, ident_defs in rec_list:     
        for entry in ident_defs:

            var 
                var_number : int
                entry_impl : NimNode

            if entry.kind == nnkSym:
                entry_impl = getTypeImpl(entry)
            elif entry.kind == nnkBracketExpr:
                entry_impl = getTypeImpl(entry[0])
            elif entry.kind == nnkPtrTy:             #the case for UGen, where variables are stored as ptr Phasor_obj, instead of Phasor       
                entry_impl = entry
            else:
                continue 
            
            #It's a ptr to something. Check if it's a pointer to an "_obj"
            if entry_impl.kind == nnkPtrTy:
                
                #Inner statement of ptr, could be a symbol (no generics, just the name) or a bracket (generics) 
                let entry_inner = entry_impl[0]

                #non-generic
                if entry_inner.kind == nnkSym:
                    let entry_inner_str = entry_inner.strVal()
                    
                    #Found it! add the position in the definition to the seq
                    if entry_inner_str[len(entry_inner_str) - 4 .. len(entry_inner_str) - 1] == "_obj":
                        var_number = index
                        var_obj_positions.add(var_number)

                #generic
                elif entry_inner.kind == nnkBracketExpr:
                    let entry_inner_str = entry_inner[0].strVal()

                    #Found it! add the position in the definition to the seq
                    if entry_inner_str[len(entry_inner_str) - 4 .. len(entry_inner_str) - 1] == "_obj":
                        var_number = index
                        var_obj_positions.add(var_number)
    
    if is_ugen_destructor_bool == true:
        proc_body.add(
            nnkCommand.newTree(
                newIdentNode("echo"),
                newLit("Calling UGen\'s destructor" )
            )   
        )
    else:
        #Generics stuff to add to destructor function declaration
        if generics.len() > 0:
            proc_def.add(generics)
        else: #no generics
            proc_def.add(newEmptyNode())

        formal_params.add(
            nnkIdentDefs.newTree(
                newIdentNode("obj"),
                ptr_bracket_expr,
                newEmptyNode()
            )
        )

        proc_def.add(formal_params)
        proc_def.add(newEmptyNode())
        proc_def.add(newEmptyNode())

        proc_body.add(
            nnkCommand.newTree(
                newIdentNode("echo"),
                newLit("Calling " & $ptr_name_str & "\'s destructor" )
            )   
        )
    
    if var_obj_positions.len() > 0:
        for var_index in var_obj_positions:
            proc_body.add(
                nnkCall.newTree(
                    newIdentNode("destructor"),
                    nnkDotExpr.newTree(
                        newIdentNode("obj"),
                        var_names[var_index]        #retrieve the correct name from the body of the struct
                    )
                )
            )

    proc_body.add(
        nnkLetSection.newTree(
            nnkIdentDefs.newTree(
                newIdentNode("obj_cast"),
                newEmptyNode(),
                nnkCast.newTree(
                    newIdentNode("pointer"),
                    newIdentNode("obj")
                )
            )
        ),
        nnkIfStmt.newTree(
            nnkElifBranch.newTree(
                nnkPrefix.newTree(
                    newIdentNode("not"),
                    nnkCall.newTree(
                        nnkDotExpr.newTree(
                            newIdentNode("obj_cast"),
                            newIdentNode("isNil")
                        )
                    )
                ),
                nnkStmtList.newTree(
                    nnkCall.newTree(
                        newIdentNode("omni_free"),
                        newIdentNode("obj_cast")
                    )
                )
            )
        )
    )

    proc_def.add(proc_body)

    final_stmt.add(proc_def)

    #echo astGenRepr final_stmt

    return quote do:
        `final_stmt`

macro addToDestructors(a : typed, original_type : typed) = 
    let 
        instance_type_inst = getTypeInst(a)
        obj_impl = getImpl(original_type)
    
    var 
        final_impl = nnkStmtList.newTree()
        generic_params : NimNode
        var_names : seq[NimNode]

    echo astGenRepr instance_type_inst

    echo astGenRepr getImpl(instance_type_inst[1][0])

#[ 
    if obj_impl[1].kind == nnkGenericParams:
        generic_params = obj_impl[1]

    for ident_defs in obj_impl[2][2]:
        var_names.add(ident_defs[0])

    if instance_type_inst.kind == nnkBracketExpr:
        var final_bracket_expr = nnkBracketExpr.newTree()

        var type_string = instance_type_inst[0].strVal()

        final_bracket_expr.add(newIdentNode(obj_impl[0].strVal()))

        type_string.add("[")
        
        for index, impl_type in instance_type_inst:
            if index == 0:
                continue
            else:
                var colon_expr = nnkExprColonExpr.newTree()

                colon_expr.add(generic_params[index - 1])
                colon_expr.add(impl_type)
            
                final_bracket_expr.add(colon_expr)

                type_string.add($impl_type.strVal() & ", ")
        
        type_string = type_string[0..type_string.len() - 3]
        type_string.add("]")

        final_bracket_expr.add(generic_params)

        final_bracket_expr.add(var_names)

        destructors_array[type_string] = final_bracket_expr ]#


macro defineDestructors() =
    #name is a string, types_inst a NimNode
    for full_typed_name, types_inst in destructors_array:
        
        let 
            obj_name = types_inst[0]
            obj_name_str = obj_name.strVal()
            ptr_name = newIdentNode(obj_name_str[0..obj_name_str.len() - 5])

        #defineDestructor(obj_name, ptr_name, types_inst[2], nil, )

    
type
    AnObj_obj[T] = object
        val : T

    AnObj[T] = ptr AnObj_obj[T]

    AnotherObj_obj[T] = object
        an_obj : T

    AnotherObj[T] = ptr AnotherObj_obj[T]

proc init[T](a : typedesc[AnObj[T]], val : T) : AnObj[T] = 
    result = cast[AnObj[T]](alloc0(sizeof(AnObj_obj[T])))
    
    #addToDestructors(result, AnObj_obj)

proc init[T](a : typedesc[AnotherObj[T]], obj : T) : AnotherObj[T] =
    result = cast[AnotherObj[T]](alloc0(sizeof(AnotherObj_obj[T])))

    addToDestructors(result, AnotherObj_obj)

let a = AnObj.init(0.5)
let b = AnotherObj.init(a)

#[ 
let a = AnObj.init("hi", 1)
let b = AnObj.init(0.5, "hi")
let c = AnObj.init(1, 0.5) ]#

defineDestructors()


{.push experimental: "codeReordering".}

type 
    AnotherObj[T] = object
        val : T


let one = AnotherObj[string](val : "hi")
let two = AnotherObj[float](val : 0.5)
let three = AnotherObj[int](val : 1)

fun(one)
fun(two)
fun(three)

proc fun(a : AnotherObj[string]) : void =
    echo "stringy string"

proc fun(a : AnotherObj[float]) : void =
    echo "floaty float"

proc fun(a : AnotherObj[int]) : void =
    echo "intsy int"

{.pop.}