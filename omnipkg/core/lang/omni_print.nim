#Simply import C's printf as debug
proc printf*(formatstr: cstring) : cint {.importc, varargs, header: "<stdio.h>", cdecl.}

#Also have some wrappers for floats, ints, etc...
proc print*(str : string) : void =
    discard printf("%s \n", str)

proc print*[T : SomeInteger](val : T) : void =
    discard printf("%d \n", int(val))

proc print*[T : SomeFloat](val : T) : void =
    discard printf("%f \n", float(val))