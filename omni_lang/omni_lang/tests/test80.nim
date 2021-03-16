omni_debug_macros:
  struct Ah[T]:
    a T
  
  def newAh[T](a):
    return Ah[T](a)

  struct Something:
    data Data
    delay Delay = Delay(samplerate)
    bubu = Data[int](10)
    ah Ah[int] = newAh[int](20)

init:
  # a = Data[Data[float]](10)
  b = Data[Something](10)
  
  c = new Data[Data[Data[Data[Data[Something]]]]]

sample:discard

