when defined(omni_embed):
  #Redefining STRING_LITERAL to be including __attribute__(section).
  #It needs to be in its own module or it will overwrite all implementations of STRING_LITERAL
  {.emit:
  """
#define STRING_LITERAL(name, str, length) \
  __attribute__((section(".omni_tar,\"aw\""))) static const struct {                   \
    TGenericSeq Sup;                      \
    NIM_CHAR data[(length) + 1];          \
} name = {{length, (NI) ((NU)length | NIM_STRLIT_FLAG)}, str}
  """ 
  .}

  const omni_tar_xz_file* = staticRead("build/omni.tar.xz")
