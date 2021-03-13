# omni_debug_macros:
struct Something[T]:
  a T

def newSomething:
  return Data(10)

struct SomethingElse[T]:
  # something Something[T]
  something = Something[T](samplerate)
  # something2 = newSomething()
  
init:
  a = SomethingElse()
  b = SomethingElse[int]()

sample: discard
