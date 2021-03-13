omni_debug_macros:
  struct Something[T]:
    a T

  def newSomething:
    return Something()

  struct SomethingElse:
    something = Something(samplerate)
    # something2 = newSomething()
  
init:
  a = SomethingElse()

sample: discard
