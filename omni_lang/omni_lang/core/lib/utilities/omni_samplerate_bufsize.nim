#C file to compile together
{.compile: "./omni_samplerate_bufsize.c".}

#Pass optimization flag to C compiler
{.passC: "-O3".}

proc omni_get_samplerate_C*() : cdouble {.importc: "omni_get_samplerate_C", cdecl.}
proc omni_get_bufsize_C*()    : cint    {.importc: "omni_get_bufsize_C", cdecl.}

proc omni_get_samplerate*() : float {.inline.} =
    return float(omni_get_samplerate_C())

proc omni_get_bufsize*() : int {.inline.} =
    return int(omni_get_bufsize_C())

#Make this just samplerate
template get_samplerate*() : untyped =
    omni_get_samplerate()

#Make this just bufsize
template get_bufsize*() : untyped =
    omni_get_bufsize()