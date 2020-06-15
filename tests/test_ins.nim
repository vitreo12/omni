import unittest
import ../omni_lang/omni_lang
import testutils_ins
import macros

suite "ins_number":
  expandMacros(ins 5)
  alloc_ins_Nim(5)

  #Check num of inputs
  test "number of inputs":
    check (omni_inputs == 5)

  #Check empty name
  test "input names":
    check (omni_input_names_const == "__NO_PARAM_NAMES__")
    check (omni_input_names_let == "__NO_PARAM_NAMES__") 

  #Check default values
  test "default values":
    check (omni_defaults_const == [0.0'f32, 0.0'f32, 0.0'f32, 0.0'f32, 0.0'f32])
    check (omni_defaults_let   == [0.0'f32, 0.0'f32, 0.0'f32, 0.0'f32, 0.0'f32])

  #Check that the templates exist
  test "templates exist":
    check (declared(in1)); check (declared(in2)); check (declared(in3)); check (declared(in4)); check (declared(in5))
    check (declared(arg1)); check (declared(arg2)); check (declared(arg3)); check (declared(arg4)); check (declared(arg5))

  #Check the values in ins_Nim
  test "templates values":
    check (in1 == 0.75); check (in2 == 0.75); check (in3 == 0.75); check (in4 == 0.75); check (in5 == 0.75)
    check (arg1 == 0.75); check (arg2 == 0.75); check (arg3 == 0.75); check (arg4 == 0.75); check (arg5 == 0.75)

  #Check get_dynamic_input
  test "get_dynamic_input":
    check (declared(get_dynamic_input))
    check (get_dynamic_input(ins_Nim, 0, 0) == 0.75)
    check (get_dynamic_input(ins_Nim, 1, 0) == 0.75)
  
  #Check C exported functions
  test "exported C functions":
    check (Omni_UGenInputs() == int32(5))

    var t = cast[ptr UncheckedArray[cchar]](Omni_UGenInputNames)
    for i in 0..10:
      echo t[i]
      
    #check (cast[string](Omni_UGenInputNames()) == "__NO_PARAM_NAMES__")

  dealloc_ins_Nim(5)
