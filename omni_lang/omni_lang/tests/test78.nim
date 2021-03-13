omni_debug_macros:
  struct Something[T]:
    a T

  struct SomethingElse:
    something = Something(samplerate)
  
init:
  a = SomethingElse()

sample: discard
