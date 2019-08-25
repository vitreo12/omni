#Simply import C's printf as debug
proc print*(formatstr: cstring) {.importc: "printf", header: "<stdio.h>", varargs.}

#Also have some wrappers for floats, ints, etc...