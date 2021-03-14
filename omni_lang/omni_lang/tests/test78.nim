# omni_debug_macros:
struct Something[T]:
  a T

def newData[T]:
  return Data[T](samplerate)

struct SomethingElse[T]:
  something Something[T]
  something2 = Something[T](samplerate) #using a constructor: type is inferred
  something3 Data[T] = newData[T]() #not calling a constructor: must be explicit on the type!

init:
  a = SomethingElse()
  b = SomethingElse[int]()

sample: discard
