# omni_debug_macros:
def someFunc[T](a T):
  return a 

sample:
  out1 = someFunc[int](10)

# proc someFunc_inner[T : SomeNumber]() : auto =
#   return T(0.5)

# template someFunc(G1 : typedesc = typedesc[float]) : untyped =
#   someFunc_inner[G1]()

# echo someFunc(int)
