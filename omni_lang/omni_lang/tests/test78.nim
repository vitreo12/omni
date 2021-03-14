# omni_debug_macros:
struct Something[T]:
  a T

def newData:
  return Data(samplerate)

struct SomethingElse[T]:
  something Something[T]
  something2 = Something[T](samplerate) #using a constructor: type is inferred
  something3 Data = newData() #not calling a constructor: must be explicit on the type!

init:
  a = SomethingElse()
  b = SomethingElse[int]()

sample: discard
