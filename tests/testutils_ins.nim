template alloc_ins_Nim*(n : int) : untyped =
  let ins_Nim {.inject.} = cast[CDoublePtrPtr](system.alloc(sizeof(CDoublePtr) * n))
  for i in 0..(n-1):
    ins_Nim[i] = cast[CDoublePtr](system.alloc(sizeof(float)))
    ins_Nim[i][0] = 0.75 #Whatever value

template dealloc_ins_Nim*(n : int) : untyped =
  for i in 0..(n-1):
    dealloc(cast[pointer](ins_Nim[i]))
  dealloc(cast[pointer](ins_Nim))
