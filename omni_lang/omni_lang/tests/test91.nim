struct Something:
  a

struct SomethingElse:
  something = Something()

omni_debug_macros:
  def test():
    somethingElse = SomethingElse()
    somethingElse.something.a = 1
    return (0, 2)

  init:
    test()
    a = 20

  sample: discard
