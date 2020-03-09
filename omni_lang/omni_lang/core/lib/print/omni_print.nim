#C file to compile together
{.compile: "./omni_print.c".}

#Pass optimization flag to C compiler
{.passC: "-O3".}

proc omni_print*(formatstr: cstring) : void {.importc: "omni_print_C", varargs, cdecl.}

#string
template print*(str : string) : untyped =
    omni_print(str & "\n")

#These don't work in max...
#[
#int
template print*[T : SomeInteger](val : T) : untyped =
    omni_print("%d\n", int(val))

#float
template print*[T : SomeFloat](val : T) : untyped =
    omni_print("%f\n", float(val))
]#