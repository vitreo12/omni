# omni_debug_macros:
struct Something[T]:
  a T

def newData[T](size = 200):
  return Data[T](size)

omni_debug_macros:
  struct SomethingElse[T]:
    a = 0.5
    b int = 3
    something Something[T]
    something2 = Something[T](samplerate) #using a constructor: type is inferred
    data Data[T] = newData[T]() #not calling a constructor: must be explicit on the type!

  init:
    a = SomethingElse()
    b = SomethingElse[int]()

  sample: discard
