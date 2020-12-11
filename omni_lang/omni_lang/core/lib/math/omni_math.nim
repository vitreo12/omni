# MIT License
# 
# Copyright (c) 2020 Francesco Cameli
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import math

# ========= #
# Constants #
# ========= #

const
    PI*    = 3.1415926535897932384626433
    pi*    = PI
    TWOPI* = 2.0 * PI
    twopi* = TWOPI
    E*     = 2.71828182845904523536028747

# ========= #
# Operators #
# ========= #

#Generate operator functions that work for any number type
template omni_operator_proc(proc_name : untyped) : untyped {.dirty.} =
    proc `proc_name`*[T : SomeNumber, Y : SomeNumber](a : T, b : Y) : auto {.inline.} =
        when Y is SomeFloat:
            return `proc_name`(Y(a), b)
        else:
            return `proc_name`(a, T(b))

template omni_operator_proc_no_return(proc_name : untyped) : untyped {.dirty.} =
    #Y as float is already implemented in nim
    proc `proc_name`*[T : SomeFloat, Y : SomeInteger](a : var T, b : Y) : auto {.inline.} =
        `proc_name`(a, T(b))

    proc `proc_name`*[T : SomeInteger, Y : SomeFloat](a : var T, b : Y) : auto {.inline.} =
        `proc_name`(a, T(b))

# != / >= / > are declared as templates: 
# It's enough to declare for the == / <= / < counterparts, or it will error out!
omni_operator_proc(`==`)
omni_operator_proc(`<`)
omni_operator_proc(`<=`)

omni_operator_proc(`+`)
omni_operator_proc(`-`)
omni_operator_proc(`*`)

omni_operator_proc(`min`)
omni_operator_proc(`max`)

#What about /= and %= ?
omni_operator_proc_no_return(`+=`)
omni_operator_proc_no_return(`-=`)
omni_operator_proc_no_return(`*=`)

# ================= #
# safemod / safediv #
# ================= #

#Going to replace "%" and "mod" with "safemod"
proc safemod*[T : SomeNumber, Y : SomeNumber](a : T, b : Y) : auto {.inline.} =
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

#Going to replace "/" and "div" with "safediv"
proc safediv*[T : SomeNumber, Y : SomeNumber](a : T, b : Y) : auto {.inline.} =
    when Y is SomeFloat:
        if b != Y(0):
            return Y(a) / b
        else:
            return Y(0)
    else:
        if b != Y(0):
            return a / T(b)
        else:
            return 0.0

#/ identifier (going to be replaced with safediv after parsing). Keeping safemod so that nim's parser it's happy with return type
proc `/`*[T : SomeNumber, Y : SomeNumber](a : T, b : Y) : auto {.inline.} =
    return safediv(a, b)

proc `div`*[T : SomeNumber, Y : SomeNumber](a : T, b : Y) : auto {.inline.} =
    return safediv(a, b)

#% identifier (going to be replaced with safemod after parsing). Keeping safemod so that nim's parser it's happy with return type
proc `%`*[T : SomeNumber, Y : SomeNumber](a : T, b : Y) : auto {.inline.} =
    return safemod(a, b)

#To make untyped parser correctly pass through
proc `mod`*[T : SomeFloat, Y : SomeFloat](a : T, b : Y) : auto {.inline.} =
    return safemod(a, b)

# ================== #
# Bitwise operations #
# ================== #

proc `&`*[T : SomeInteger, Y : SomeInteger](a : T, b : Y) : auto {.inline.} =
    return a and b

proc `|`*[T : SomeInteger, Y : SomeInteger](a : T, b : Y) : auto {.inline.} =
    return a or b

#This collides with the pow operation ^
#proc `^`*[T : SomeInteger, Y : SomeInteger](a : T, b : Y) : auto {.inline.} =
#    return a xor b

proc `<<`*[T : SomeInteger, Y : SomeInteger](a : T, b : Y) : auto {.inline.} =
    return a shl b

proc `>>`*[T : SomeInteger, Y : SomeInteger](a : T, b : Y) : auto {.inline.} =
    return a shr b

proc `~`*[T : SomeInteger, Y : SomeInteger](a : T) : auto {.inline.} =
    return not a

# =============================== #
# Wrappers for math.nim operators #
# =============================== #

proc fixdenorm*[T : SomeNumber](x : T) : auto {.inline.} =
    when T isnot SomeFloat:
        let float_x = float(x)
    else:
        let float_x = x
    
    #Don't know why but result != result checks for nans (it's in the classify function in math modules)
    #Also, this inf / neginf comparison is quite slow, as the C code actually translates to (for neg inf) 1.0 / 0.0, so it's an extra division operation!
    #Comparison should be done with the IEEE represenation of inf / neginf / nan    
    if float_x == Inf or float_x == NegInf or float_x != float_x:
        return T(0.0)
    return x

#Turn any one input math function into a generic one thatalso supports integers
template omni_math_proc(proc_name : untyped) : untyped {.dirty.} =
    proc `proc_name`*[T : SomeNumber](x : T) : float {.inline.} =
        when T isnot SomeFloat:
            return math.`proc_name`(float(x))
        else:
            return math.`proc_name`(x)

template omni_math_proc_check_inf(proc_name : untyped) : untyped {.dirty.} =
    proc `proc_name`*[T : SomeNumber](x : T) : float {.inline.} =
        when T isnot SomeFloat:
            result = math.`proc_name`(float(x))
        else:
            result = math.`proc_name`(x)
        #Don't know why but result != result checks for nans (it's in the classify function in math modules)
        #Also, this inf / neginf comparison is quite slow, as the C code actually translates to (for neg inf) 1.0 / 0.0, so it's an extra division operation!
        #Comparison should be done with the IEEE represenation of inf / neginf / nan
        if result == Inf or result == NegInf or result != result:
            result = 0.0

#nextPowerOfTwo is the only one with ints
proc nextPowerOfTwo*[T : SomeNumber](x : T) : T =
    when T isnot SomeInteger:
        return T(nextPowerOfTwo(int(x)))
    else:
        return nextPowerOfTwo(x)

#pow is the only one with 2 inputs
proc pow*[T : SomeNumber, Y : SomeNumber](x : T, y : Y) : float {.inline.} =
    when T isnot SomeFloat:
        when Y isnot SomeFloat:
            return math.pow(float(x), float(y))
        else:
            return math.pow(float(x), y)
    else:
        when Y isnot SomeFloat:
            return math.pow(x, float(y))
        else:
            return math.pow(x, y)

#alternative syntax for pow
proc `^`*[T : SomeNumber, Y: SomeNumber](x : T, y : Y) : float {.inline.} =
    return omni_math.pow(x, y)

#log is the only one with 2 inputs and check for inf/neginf/nan
proc log*[T : SomeNumber, Y : SomeNumber](x : T, base : Y) : float {.inline.} =
    when T isnot SomeFloat:
        when Y isnot SomeFloat:
            result = math.log(float(x), float(base))
        else:
            result = math.log(float(x), base)
    else:
        when Y isnot SomeFloat:
            result = math.log(x, float(base))
        else:
            result = math.log(x, base)
    #Don't know why but result != result checks for nans (it's in the classify function in math modules)
    #Also, this inf / neginf comparison is quite slow, as the C code actually translates to (for neg inf) 1.0 / 0.0, so it's an extra division operation!
    #Comparison should be done with the IEEE represenation of inf / neginf / nan
    if result == Inf or result == NegInf or result != result:
        result = 0.0

omni_math_proc_check_inf(ln)
omni_math_proc_check_inf(log2)
omni_math_proc_check_inf(log10)
omni_math_proc_check_inf(gamma)
omni_math_proc_check_inf(lgamma)
omni_math_proc(sqrt)
omni_math_proc(cbrt)
omni_math_proc(exp)
omni_math_proc(hypot)
omni_math_proc(erf)
omni_math_proc(erfc)
omni_math_proc(floor)
omni_math_proc(ceil)
omni_math_proc(round)
omni_math_proc(trunc)
omni_math_proc(degToRad)
omni_math_proc(radToDeg)
omni_math_proc(sgn)
omni_math_proc(sin)
omni_math_proc(cos)
omni_math_proc(tan)
omni_math_proc(sinh)
omni_math_proc(cosh)
omni_math_proc(tanh)
omni_math_proc(arccos)
omni_math_proc(arcsin)
omni_math_proc(arctan)
omni_math_proc(arctan2)
omni_math_proc(arcsinh)
omni_math_proc(arccosh)
omni_math_proc(arctanh)
omni_math_proc(cot)
omni_math_proc(sec)
omni_math_proc(csc)
omni_math_proc(coth)
omni_math_proc(sech)
omni_math_proc(csch)
omni_math_proc(arccot)
omni_math_proc(arcsec)
omni_math_proc(arccsc)
omni_math_proc(arccoth)
omni_math_proc(arcsech)
omni_math_proc(arccsch)

# ========= #
# Iterators #
# ========= #

#Should these be all ints, instead of T(x) ???
iterator items*[T : SomeFloat, Y : SomeInteger](s : HSlice[T, Y]) : auto {.inline.} =
    for x in int(s.a) .. (s.b):
        yield T(x)

iterator items*[T : SomeInteger, Y : SomeFloat](s : HSlice[T, Y]) : auto {.inline.} =
    for x in (s.a) .. int(s.b):
        yield T(x)

iterator items*[T : SomeFloat, Y : SomeFloat](s : HSlice[T, Y]) : auto {.inline.} =
    for x in int(s.a) .. int(s.b):
        yield T(x)

#Generics don't work here
iterator `..`*(a : SomeFloat, b : SomeFloat) : auto {.inline.} =
    var res = int(a)
    while res <= int(b):
        yield typeof(a)(res)
        inc(res)

iterator `..`*(a : SomeFloat, b : SomeInteger) : auto {.inline.} =
    var res = int(a)
    while res <= b:
        yield typeof(a)(res)
        inc(res)

iterator `..`*(a : SomeInteger, b : SomeFloat) : auto {.inline.} =
    var res = a
    while res <= int(b):
        yield res
        inc(res)

iterator `..<`*(a : SomeFloat, b : SomeFloat) : auto {.inline.} =
    var res = int(a)
    while res < int(b):
        yield typeof(a)(res)
        inc(res)

iterator `..<`*(a : SomeFloat, b : SomeInteger) : auto {.inline.} =
    var res = int(a)
    while res < b:
        yield typeof(a)(res)
        inc(res)

iterator `..<`*(a : SomeInteger, b : SomeFloat) : auto {.inline.} =
    var res = a
    while res < int(b):
        yield res
        inc(res)