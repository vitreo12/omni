#import / export all maths functions
import math
export math

# WRITE WRAPPERS FOR integers FOR ALL MATHS FUNCTIONS THAT ONLY TAKE FLOAT!
# ...
# ...

#Dummy % identifier (going to be replaced with safemod after parsing)
proc `%`*[T : SomeNumber, Y : SomeNumber](a : T, b : Y) : T {.inline.} =
    discard

#Going to replace "%" and "mod"
proc safemod*[T : SomeNumber, Y : SomeNumber](a : T, b : Y) : T {.inline.} =
    when Y is SomeFloat:
        if b != Y(0):
            return Y(a) mod b
        else:
            return Y(0)
    else:
        if b != Y(0):
            return a mod T(b)
        else:
            return T(0)

#Going to replace "/" and "div"
proc safediv*[T : SomeNumber, Y : SomeNumber](a : T, b : Y) : T {.inline.} =
    when Y is SomeFloat:
        if b != Y(0):
            return Y(a) / b
        else:
            return Y(0)
    else:
        if b != Y(0):
            return a / T(b)
        else:
            return T(0)