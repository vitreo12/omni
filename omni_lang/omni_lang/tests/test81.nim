# omni_debug_macros:
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

init:
  a = Something(g = Data())

sample: discard
