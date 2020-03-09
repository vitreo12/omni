#C file to compile together
{.compile: "./omni_print.c".}

#Pass optimization flag to C compiler
{.passC: "-O3".}

proc omni_print_C*(formatstr: cstring) : cint {.importc: "omni_print_C", varargs, cdecl.}

proc omni_print*(formatstr: cstring) : int {.varargs.} =
    return int(omni_print_C(formatstr))

#string
proc print*(str : string) : void {.inline.} =
    discard omni_print("%s \n", str)

#int
proc print*[T : SomeInteger](val : T) : void {.inline.} =
    discard omni_print("%d \n", int(val))

#float
proc print*[T : SomeFloat](val : T) : void {.inline.} =
    discard omni_print("%f \n", float(val))