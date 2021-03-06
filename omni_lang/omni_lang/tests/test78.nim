omni_debug_macros:
  struct Phasor[T]:
    phase
    data Data[T]

  struct Sine[T] of Phasor[T]:
    amp

  struct MyData[T] of Phasor[Data[T]]:
    something
    anotherData Data
