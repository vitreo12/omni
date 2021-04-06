# omni_debug_macros:
def someFunc():
    return Data(10)

struct Something:
  a = Data.new
  b = Data[float].new
  c = new Data
  d = new Data[float]
  e = Data.new(100)
  f = Data[float].new(100)
  g = new Data(100)
  h = new Data[float](100)
  i = Data(100)
  l = Data[float](100)
  k Data = new Data
  m Data = someFunc()
  n = 10
  o int = 10
  p bool = false
  q = true

  data Data
  val int
  val2 float
  val3 bool

init:
  a = Something()
  print a.q

sample: discard
