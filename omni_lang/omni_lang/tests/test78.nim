omni_debug_macros:
  struct Something:
    a

  struct SomethingElse:
    something = Something(samplerate)
  
  init:
    a = SomethingElse()
    print a.something.a

  sample: discard
