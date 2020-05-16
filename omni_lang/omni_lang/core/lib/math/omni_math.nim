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
#export math

# ========= #
# Operators #
# ========= #

proc `+`*[T : SomeNumber, Y : SomeNumber](a : T, b : Y) : auto {.inline.} =
    when Y is SomeFloat:
        return Y(a) + b
    else:
        return a + T(b)

proc `-`*[T : SomeNumber, Y : SomeNumber](a : T, b : Y) : auto {.inline.} =
    when Y is SomeFloat:
        return Y(a) - b
    else:
        return a - T(b)

proc `*`*[T : SomeNumber, Y : SomeNumber](a : T, b : Y) : auto {.inline.} =
    when Y is SomeFloat:
        return Y(a) * b
    else:
        return a * T(b)

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

#% identifier (going to be replaced with safemod after parsing). Keeping safemod so that nim's parser it's happy with return type
proc `%`*[T : SomeNumber, Y : SomeNumber](a : T, b : Y) : auto {.inline.} =
    return safemod(a, b)

# ================== #
# Bitwise operations #
# ================== #

proc `&`*[T : SomeInteger, Y : SomeInteger](a : T, b : Y) : auto {.inline.} =
    return a and b

proc `|`*[T : SomeInteger, Y : SomeInteger](a : T, b : Y) : auto {.inline.} =
    return a or b

#This collides with the pow operation ^
proc `^`*[T : SomeInteger, Y : SomeInteger](a : T, b : Y) : auto {.inline.} =
    return a xor b

proc `<<`*[T : SomeInteger, Y : SomeInteger](a : T, b : Y) : auto {.inline.} =
    return a shl b

proc `>>`*[T : SomeInteger, Y : SomeInteger](a : T, b : Y) : auto {.inline.} =
    return a shr b

proc `~`*[T : SomeInteger, Y : SomeInteger](a : T) : auto {.inline.} =
    return not a

# ================== #
# WRAPPING / FOLDING #
# ================== #

proc fold*[V : SomeNumber, L : SomeNumber, H : SomeNumber](v : V, lo1 : L, hi1 : H) : auto {.inline.} =
    var 
        lo : L
        hi : H
    
    var out_v = v
    
    if lo1 == hi1:
        return lo1

    if lo1 > hi1:
        hi = lo1 
        lo = hi1
    else:
        lo = lo1 
        hi = hi1

    let diff = hi - lo
    var numWraps = 0
    
    if out_v >= hi:
        out_v -= diff
        if out_v >= hi:
            numWraps = int((out_v - lo) / diff)
            out_v -= diff * V(numWraps)
        numWraps+=1
    elif out_v < lo:
        out_v += diff
        if out_v < lo:
            numWraps = int((out_v - lo) / diff) - 1.0
            out_v -= diff * V(numWraps)
        numWraps-=1
    
    if numWraps and 1:
         out_v = hi + lo - out_v

    return v;

proc wrap*[V : SomeNumber, L : SomeNumber, H : SomeNumber](v : V, lo1 : L, hi1 : H) : auto {.inline.} =
    var 
        lo : L
        hi : H
    
    var out_v = v

    if lo1 == hi1:
        return lo1

    if lo1 > hi1: 
        hi = lo1 
        lo = hi1
    else:
        lo = lo1
        hi = hi1
    
    let diff = hi - lo
    if out_v >= lo and out_v < hi:
        return v

    if diff <= 0.000000001:
        return lo

    let numWraps : int = int((out_v - lo) / diff) - int(out_v < lo)
    return v - diff * V(numWraps)

proc clamp*[X : SomeNumber, M1 : SomeNumber, M2 : SomeNumber](x : X, min_val : M1, max_val : M2) : X {.inline.} =
    if x > X(max_val):
        return X(max_val)
    elif x < X(min_val):
        return X(min_val)
    return x

# ======================= #
# Interpolation functions #
# ======================= #

proc linear_interp*[A : SomeNumber, X : SomeNumber, Y : SomeNumber](a : A, x : X, y : Y) : auto {.inline.} =
    return x + (a * (y - x))

proc cubic_interp*[A : SomeNumber, W : SomeNumber, X : SomeNumber, Y : SomeNumber, Z : SomeNumber](a : A, w : W, x : X, y : Y, z : Z) : auto {.inline.} =
    let
        a2 : float = a * a
        f0 : float = z - y - w + x
        f1 : float = w - x - f0
        f2 : float = y - w
        f3 : float = x

    return (f0 * a * a2) + (f1 * a2) + (f2 * a) + f3

proc spline_interp*[A : SomeNumber, W : SomeNumber, X : SomeNumber, Y : SomeNumber, Z : SomeNumber](a : A, w : W, x : X, y : Y, z : Z) : auto {.inline.} =
    let
        a2 : float = a * a
        f0 : float = (-0.5 * w) + (1.5 * x) - (1.5 * y) + (0.5 * z)
        f1 : float = w - (2.5 * x) + (2.0 * y) - (0.5 * z)
        f2 : float = (-0.5 * w) + (0.5 * y)
    
    return (f0 * a * a2) + (f1 * a2) + (f2 * a) + x

# =============================== #
# Wrappers for math.nim operators #
# =============================== #

#Turn any one input math function into a generic one thatalso supports integers
template omniMathFunction(func_name : untyped) : untyped {.dirty.} =
    proc `func_name`*[T : SomeNumber](x : T) : float {.inline.} =
        when T isnot SomeFloat:
            return math.`func_name`(float(x))
        else:
            return math.`func_name`(x)

template omniMathFunctionCheckInf(func_name : untyped) : untyped {.dirty.} =
    proc `func_name`*[T : SomeNumber](x : T) : float {.inline.} =
        when T isnot SomeFloat:
            result = math.`func_name`(float(x))
        else:
            result = math.`func_name`(x)
        #Don't know why but result != result checks for nans (it's in the classify function in math modules)
        #Also, this inf / neginf comparison is quite slow, as the C code actually translates to (for neg inf) 1.0 / 0.0, so it's an extra division operation!
        if result == Inf or result == NegInf or result != result:
            result = 0.0

#log is the only one with 2 inputs
proc log*[T : SomeNumber, Y : SomeNumber](x : T, base : Y) : float {.inline.} =
    when T isnot SomeFloat:
        result = math.log(float(x), float(base))
    else:
         result = math.log(x, base)
    #Don't know why but result != result checks for nans (it's in the classify function in math modules)
    #Also, this inf / neginf comparison is quite slow, as the C code actually translates to (for neg inf) 1.0 / 0.0, so it's an extra division operation!
    if result == Inf or result == NegInf or result != result:
        result = 0.0

omniMathFunctionCheckInf(ln)
omniMathFunctionCheckInf(log2)
omniMathFunctionCheckInf(log10)
omniMathFunctionCheckInf(gamma)
omniMathFunctionCheckInf(lgamma)
omniMathFunction(sqrt)
omniMathFunction(cbrt)
omniMathFunction(exp)
omniMathFunction(hypot)
omniMathFunction(pow)
omniMathFunction(erf)
omniMathFunction(erfc)
omniMathFunction(floor)
omniMathFunction(ceil)
omniMathFunction(round)
omniMathFunction(trunc)
omniMathFunction(degToRad)
omniMathFunction(radToDeg)
omniMathFunction(sgn)
omniMathFunction(sin)
omniMathFunction(cos)
omniMathFunction(tan)
omniMathFunction(sinh)
omniMathFunction(cosh)
omniMathFunction(tanh)
omniMathFunction(arccos)
omniMathFunction(arcsin)
omniMathFunction(arctan)
omniMathFunction(arctan2)
omniMathFunction(arcsinh)
omniMathFunction(arccosh)
omniMathFunction(arctanh)
omniMathFunction(cot)
omniMathFunction(sec)
omniMathFunction(csc)
omniMathFunction(coth)
omniMathFunction(sech)
omniMathFunction(csch)
omniMathFunction(arccot)
omniMathFunction(arcsec)
omniMathFunction(arccsc)
omniMathFunction(arccoth)
omniMathFunction(arcsech)
omniMathFunction(arccsch)


#[
inline double atodb(double in) {
    return double((in <= 0.) ? -999. : (20. * log10(in)));
}

inline double dbtoa(double in) {
    return double(pow(10., in * 0.05));
}

inline double ftom(double in, double tuning=440.) {
    return double(69. + 17.31234050465299 * log(safediv(in, tuning)));
}

inline double mtof(double in, double tuning=440.) {
    return double(tuning * exp(.057762265 * (in - 69.0)));
}

inline double mstosamps(double ms, double samplerate=44100.) {
    return double(samplerate * ms * double(0.001));
}

inline double sampstoms(double s, double samplerate=44100.) {
    return double(double(1000.) * s / samplerate);
}
]#