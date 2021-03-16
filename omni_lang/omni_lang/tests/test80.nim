omni_debug_macros:
  struct Something:
    data Data
    delay Delay

init:
  # a = Data[Data[float]](10)
  b = Data[Something](10)
  
  c = new Data[Data[Data[Data[Data[Something]]]]]

sample:discard

