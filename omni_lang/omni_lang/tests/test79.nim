omni_debug_macros:
  def someFunc[T, Y](a T, b Y = 3):
    return a 

  sample:
    out1 = someFunc[int](0)

# template someFunc(G1 : typedesc = typedesc[float]) : untyped =
#   someFunc_inner[G1]()

# echo someFunc(int)


# proc test(T : typedesc = typedesc[float], b : T) : auto =
#     return b * 2

# echo test(b=0.5, T = typedesc[float])
