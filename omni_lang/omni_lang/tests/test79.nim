# omni_debug_macros:
#   def someFunc[T, Y](a T = 0, b Y = 3):
#     return a * b 

#   sample:
#     # out1 = test79_someFunc_omni_def[int, float](0, 0, samplerate, bufsize, omni_auto_mem, omni_call_type)
#     out1 = someFunc[int, float](0)

# proc someFunc_inner[T : SomeNumber]() : auto =
#   return T(0.5)

# template someFunc(G1 : typedesc = typedesc[float]) : untyped =
#   someFunc_inner[G1]()

# echo someFunc(int)

import macros

macro mh(t : typed) =
  error repr t

mh:
  proc test(T : typedesc[SomeNumber] = float, a : T = 0.5) : T =
      return a * 2

  echo test(a = 0.5)
