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

proc findTwoStructRecursiveAA*(t : NimNode, is_t_a_variable : bool = true, struct1_to_find : string, struct2_to_find : string, original_object_name : string, full_structs1_path : var seq[string], full_structs2_path : var seq[string]) : void {.compileTime.} =
    var type_def : NimNode

    #Some generic types
    if t.kind == nnkIdent:
        return
    
    #if t is a variable name, retrieve type from it. If it's already a type, get it's type implementation right away
    if is_t_a_variable:
        type_def = getTypeImpl(t)
    else:
        let type_impl = getImpl(t)
        if type_impl.len < 2:
            return
        type_def = type_impl[2]
    
    var actual_type_def : NimNode

    #echo astGenRepr type_def

    #If it's a pointer, exctract
    if type_def.kind == nnkPtrTy:   
        #if generic
        if type_def[0].kind == nnkBracketExpr:
            actual_type_def = getTypeImpl(type_def[0][0])
        else:
            actual_type_def = getTypeImpl(type_def[0])

    #Pass the definition through
    else:
        actual_type_def = type_def

    #If it's not an object type, abort the search.
    if actual_type_def.kind != nnkObjectTy:
        return

    let rec_list = actual_type_def[2]

    for ident_defs in rec_list:
        var
            var_name = ident_defs[0]
            var_type = ident_defs[1]
        
        var type_to_inspect : NimNode

        #if ptr
        if var_type.kind == nnkPtrTy:
            var_type = var_type[0]
        
        #if generic
        if var_type.kind == nnkBracketExpr:
            type_to_inspect = var_type[0]
        else:
            type_to_inspect = var_type
        
        let var_name_kind = var_name.kind

        if var_name_kind != nnkIdent and var_name_kind != nnkSym:
            return

        let 
            type_to_inspect_string = type_to_inspect.strVal()
            interp_var_name = $original_object_name & "." & $(var_name.strVal())
        
        #Found the struct type we've been searching for!
        if type_to_inspect_string == struct1_to_find or type_to_inspect_string == (struct1_to_find & "_obj"):
            echo "Found struct: ", interp_var_name
            full_structs1_path.add(interp_var_name)

        #Found the struct type we've been searching for!
        if type_to_inspect_string == struct2_to_find or type_to_inspect_string == (struct2_to_find & "_obj"):
            echo "Found struct: ", interp_var_name
            full_structs2_path.add(interp_var_name)
        
        #Run the function recursively. t is now a type for sure.
        findTwoStructRecursiveAA(type_to_inspect, false, struct1_to_find, struct2_to_find, interp_var_name, full_structs1_path, full_structs2_path)




proc findTwoStructRecursive*(t : NimNode, is_t_a_variable : bool = true, struct1_to_find : string, struct2_to_find : string, original_object_name : string, full_structs1_path : var seq[string], full_structs2_path : var seq[string], full_data_datas_paths : var seq[string], full_buffer_datas_paths : var seq[string], is_data : bool = false) : void {.compileTime.} =
    var type_def : NimNode

    #Some generic types
    if t.kind == nnkIdent:
        return
    
    if t.kind != nnkSym:
        return

    #if t is a variable name, retrieve type from it. If it's already a type, get it's type implementation right away
    if is_t_a_variable:
        type_def = getTypeImpl(t)
    else:
        let type_impl = getImpl(t)
        if type_impl.len < 2:
            return
        type_def = type_impl[2]
    
    var actual_type_def : NimNode

    #echo astGenRepr type_def

    #If it's a pointer, exctract
    if type_def.kind == nnkPtrTy:   
        #if generic
        if type_def[0].kind == nnkBracketExpr:
            actual_type_def = getTypeImpl(type_def[0][0])
        else:
            actual_type_def = getTypeImpl(type_def[0])

    #Pass the definition through
    else:
        actual_type_def = type_def

    #If it's not an object type, abort the search.
    if actual_type_def.kind != nnkObjectTy:
        return

    let rec_list = actual_type_def[2]

    for ident_defs in rec_list:
        var
            var_name = ident_defs[0]
            var_type = ident_defs[1]
        
        var 
            type_to_inspect : NimNode
            type_to_inspect_string : string
            interp_var_name : string

        #if ptr
        if var_type.kind == nnkPtrTy:
            var_type = var_type[0]
        
        #if generic
        if var_type.kind == nnkBracketExpr:
            type_to_inspect = var_type[0]
            type_to_inspect_string = type_to_inspect.strVal()
            let generic_type = var_type[1]
            interp_var_name = $original_object_name & "." & $(var_name.strVal())
            if type_to_inspect_string == "Data_obj" or type_to_inspect_string == "Data":
                findTwoStructRecursive(generic_type, false, struct1_to_find, struct2_to_find, interp_var_name, full_data_datas_paths, full_buffer_datas_paths, full_data_datas_paths, full_buffer_datas_paths, true)
        else:
            type_to_inspect = var_type
        
        let var_name_kind = var_name.kind

        if var_name_kind != nnkIdent and var_name_kind != nnkSym:
            return

        type_to_inspect_string = type_to_inspect.strVal()
        interp_var_name = $original_object_name & "." & $(var_name.strVal())
    
        #Found the struct type we've been searching for!
        if type_to_inspect_string == struct1_to_find or type_to_inspect_string == (struct1_to_find & "_obj"):
            #if is_data:
            #    full_structs1_path.add(original_object_name)
            full_structs1_path.add(interp_var_name)

        #Found the struct type we've been searching for!
        if type_to_inspect_string == struct2_to_find or type_to_inspect_string == (struct2_to_find & "_obj"):
            #if is_data:
            #    full_structs2_path.add(original_object_name)
            full_structs2_path.add(interp_var_name)
        
        #Run the function recursively. t is now a type for sure.
        findTwoStructRecursive(type_to_inspect, false, struct1_to_find, struct2_to_find, interp_var_name, full_structs1_path, full_structs2_path, full_data_datas_paths, full_buffer_datas_paths)



















































proc findStructRecursive*(t : NimNode, is_t_a_variable : bool = true, struct_to_find : string, original_object_name : string, full_structs_path : var seq[string]) : void {.compileTime.} =
    var type_def : NimNode

    #Some generic types
    if t.kind == nnkIdent:
        return
    
    #if t is a variable name, retrieve type from it. If it's already a type, get it's type implementation right away
    if is_t_a_variable:
        type_def = getTypeImpl(t)
    else:
        let type_impl = getImpl(t)
        if type_impl.len < 2:
            return
        type_def = type_impl[2]
    
    var actual_type_def : NimNode

    #If it's a pointer, exctract
    if type_def.kind == nnkPtrTy:
        
        #if generic
        if type_def[0].kind == nnkBracketExpr:
            actual_type_def = getTypeImpl(type_def[0][0])
        else:
            actual_type_def = getTypeImpl(type_def[0])

    #Pass the definition through
    else:
        actual_type_def = type_def

    #If it's not an object type, abort the search.
    if actual_type_def.kind != nnkObjectTy:
        return

    let rec_list = actual_type_def[2]

    for ident_defs in rec_list:
        var
            var_name = ident_defs[0]
            var_type = ident_defs[1]
        
        var type_to_inspect : NimNode

        #if ptr
        if var_type.kind == nnkPtrTy:
            var_type = var_type[0]
        
        #if generic
        if var_type.kind == nnkBracketExpr:
            type_to_inspect = var_type[0]
        else:
            type_to_inspect = var_type
        
        let var_name_kind = var_name.kind

        if var_name_kind != nnkIdent and var_name_kind != nnkSym:
            return

        let 
            type_to_inspect_string = type_to_inspect.strVal()
            interp_var_name = $original_object_name & "." & $(var_name.strVal())
        
        #Found the struct type we've been searching for!
        if type_to_inspect_string == struct_to_find or type_to_inspect_string == (struct_to_find & "_obj"):
            echo "Found struct: ", interp_var_name
            full_structs_path.add(interp_var_name)
        
        #Run the function recursively. t is now a type for sure.
        findStructRecursive(type_to_inspect, false, struct_to_find, interp_var_name, full_structs_path)