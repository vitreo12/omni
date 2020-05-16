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

#import / export all maths functions.. Should export be at the bottom?
import math
export math

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

#[ proc sqrt*(x: float32): float32
proc cbrt*(x: float32): float32
proc ln*(x: float32): float32
proc log*[T: SomeFloat](x, base: T): T # can return nan / inf
proc log10*(x: float32): float32       # can return nan / inf
proc exp*(x: float32): float32
proc sin*(x: float32): float32
proc cos*(x: float32): float32 
proc tan*(x: float32): float32
proc sinh*(x: float32): float32
proc cosh*(x: float32): float32
proc tanh*(x: float32): float32
proc arccos*(x: float32): float32
proc arcsin*(x: float32): float32
proc arctan*(x: float32): float32
proc arctan2*(y, x: float32)
proc arcsinh*(x: float32): float32
proc arccosh*(x: float32): float32 
proc arctanh*(x: float32): float32

proc cot*[T: float32|float64](x: T): T = 1.0 / tan(x)
proc sec*[T: float32|float64](x: T): T = 1.0 / cos(x)
proc csc*[T: float32|float64](x: T): T = 1.0 / sin(x)

proc coth*[T: float32|float64](x: T): T = 1.0 / tanh(x)
proc sech*[T: float32|float64](x: T): T = 1.0 / cosh(x)
proc csch*[T: float32|float64](x: T): T = 1.0 / sinh(x)

proc arccot*[T: float32|float64](x: T): T = arctan(1.0 / x)
proc arcsec*[T: float32|float64](x: T): T = arccos(1.0 / x)
proc arccsc*[T: float32|float64](x: T): T = arcsin(1.0 / x)

proc arccoth*[T: float32|float64](x: T): T = arctanh(1.0 / x)
proc arcsech*[T: float32|float64](x: T): T = arccosh(1.0 / x)
proc arccsch*[T: float32|float64](x: T): T = arcsinh(1.0 / x)



proc hypot*(x, y: float32): float32
proc pow*(x, y: float32): float32
proc erf*(x: float32): float32
proc erfc*(x: float32): float32
proc gamma*(x: float32): float32
proc lgamma*(x: float32): float32
proc floor*(x: float32): float32
proc ceil*(x: float32): float32
proc round*(x: float32): float32
proc trunc*(x: float32): float32
proc log2*(x: float32): float32
proc degToRad*[T: float32|float64](d: T): T 
proc radToDeg*[T: float32|float64](d: T): T
proc sgn*[T: SomeNumber](x: T): int ]#