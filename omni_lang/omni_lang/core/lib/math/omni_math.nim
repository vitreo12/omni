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

# WRITE WRAPPERS FOR integers FOR ALL MATHS FUNCTIONS THAT ONLY TAKE FLOAT!
# ...
# ...

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

proc `^`*[T : SomeInteger, Y : SomeInteger](a : T, b : Y) : auto {.inline.} =
    return a xor b

proc `<<`*[T : SomeInteger, Y : SomeInteger](a : T, b : Y) : auto {.inline.} =
    return a shl b

proc `>>`*[T : SomeInteger, Y : SomeInteger](a : T, b : Y) : auto {.inline.} =
    return a shr b

proc `~`*[T : SomeInteger, Y : SomeInteger](a : T) : auto {.inline.} =
    return not a

# ======================= #
# Interpolation functions #
# ======================= #

proc linear_interp*[A : SomeNumber, X : SomeNumber, Y : SomeNumber](a : A, x : X, y : Y) : auto =
    return x + (a * (y - x))

proc cubic_interp*[A : SomeNumber, W : SomeNumber, X : SomeNumber, Y : SomeNumber, Z : SomeNumber](a : A, w : W, x : X, y : Y, z : Z) : auto =
    let
        a2 : float = a * a
        f0 : float = z - y - w + x
        f1 : float = w - x - f0
        f2 : float = y - w
        f3 : float = x

    return (f0 * a * a2) + (f1 * a2) + (f2 * a) + f3

proc spline_interp*[A : SomeNumber, W : SomeNumber, X : SomeNumber, Y : SomeNumber, Z : SomeNumber](a : A, w : W, x : X, y : Y, z : Z) : auto =
    let
        a2 : float = a * a
        f0 : float = (-0.5 * w) + (1.5 * x) - (1.5 * y) + (0.5 * z)
        f1 : float = w - (2.5 * x) + (2.0 * y) - (0.5 * z)
        f2 : float = (-0.5 * w) + (0.5 * y)
    
    return (f0 * a * a2) + (f1 * a2) + (f2 * a) + x