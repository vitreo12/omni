omni_debug_macros:
  def someFunc[T](a T):
    return a 

  sample:
    out1 = someFunc[int](0)

proc someFunc_inner[T : SomeNumber]() : auto =
  return T(0.5)

# template someFunc(G1 : typedesc = typedesc[float]) : untyped =
#   someFunc_inner[G1]()

# echo someFunc(int)


# proc test(T : typedesc[SomeNumber] = float, b : T) =
#     return b * 2

# echo a(b = 0.5)
