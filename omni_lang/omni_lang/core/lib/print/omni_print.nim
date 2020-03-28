#C file to compile together
{.compile: "./omni_print.c".}

#Pass optimization flag to C compiler
{.passC: "-O3".}

proc omni_print_str_val* (format_string : cstring, value : culong) : void {.importc: "omni_print_str_val_C", cdecl.}
proc omni_print_str*     (format_string : cstring)                 : void {.importc: "omni_print_str_C", cdecl.}
proc omni_print_float*   (value : cfloat)                          : void {.importc: "omni_print_float_C", cdecl.}
proc omni_print_int*     (value : cint)                            : void {.importc: "omni_print_int_C", cdecl.}

#string
template print*(str : string) : untyped =
    omni_print_str(str)

#float
template print*[T : SomeFloat](val : T) : untyped =
    omni_print_float(cfloat(val))

#int
template print*[T : SomeInteger](val : T) : untyped =
    omni_print_int(cint(val))