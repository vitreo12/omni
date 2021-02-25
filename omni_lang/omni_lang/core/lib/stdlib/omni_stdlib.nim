# MIT License
# 
# Copyright (c) 2020-2021 Francesco Cameli
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

import ../math/omni_math

# ================= #
# Simple noise func #
# ================= #

from random import rand

proc noise*() : float {.inline.} =
    return rand(2.0) - 1.0

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

proc clip*[X : SomeNumber, M1 : SomeNumber, M2 : SomeNumber](x : X, min_val : M1, max_val : M2) : X {.inline.} =
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
    when A isnot SomeFloat:
        let float_a = float(a)
    else:
        let float_a = a

    when W isnot SomeFloat:
        let float_w = float(w)
    else:
        let float_w = w

    when X isnot SomeFloat:
        let float_x = float(x)
    else:
        let float_x = x

    when Y isnot SomeFloat:
        let float_y = float(y)
    else:
        let float_y = y

    when Z isnot SomeFloat:
        let float_z = float(z)
    else:
        let float_z = z

    let
        a2 : float = float_a * float_a
        f0 : float = float_z - float_y - float_w + float_x
        f1 : float = float_w - float_x - f0
        f2 : float = float_y - float_w
        f3 : float = float_x

    return (f0 * float_a * a2) + (f1 * a2) + (f2 * float_a) + f3

proc spline_interp*[A : SomeNumber, W : SomeNumber, X : SomeNumber, Y : SomeNumber, Z : SomeNumber](a : A, w : W, x : X, y : Y, z : Z) : auto {.inline.} =
    when A isnot SomeFloat:
        let float_a = float(a)
    else:
        let float_a = a

    when W isnot SomeFloat:
        let float_w = float(w)
    else:
        let float_w = w

    when X isnot SomeFloat:
        let float_x = float(x)
    else:
        let float_x = x

    when Y isnot SomeFloat:
        let float_y = float(y)
    else:
        let float_y = y

    when Z isnot SomeFloat:
        let float_z = float(z)
    else:
        let float_z = z

    let
        a2 : float = float_a * float_a
        f0 : float = (-0.5 * float_w) + (1.5 * float_x) - (1.5 * float_y) + (0.5 * float_z)
        f1 : float = w - (2.5 * float_x) + (2.0 * float_y) - (0.5 * float_z)
        f2 : float = (-0.5 * float_w) + (0.5 * float_y)
    
    return (f0 * float_a * a2) + (f1 * a2) + (f2 * float_a) + float_x

# ================= #
# Various utilities #
# ================= #

#Emulate omni's def behaviour in order to be able to use samplerate
proc mstosamps_inner*[T : SomeNumber](ms : T, samplerate : float) : float {.inline.} =
    return samplerate * ms * 0.001

template mstosamps*[T : SomeNumber](ms : T) : untyped {.dirty.} =
    mstosamps_inner(ms, samplerate)

proc sampstoms_inner*[T : SomeNumber](s : T, samplerate : float) : float {.inline.} =
    return 1000.0 * s / samplerate

template sampstoms*[T : SomeNumber](s : T) : untyped {.dirty.} =
    sampstoms_inner(s, samplerate)

proc atodb*[T : SomeNumber](x : T) : float {.inline.} =
    return if x <= 0.0: return -999.0 else: return 20.0 * log10(x)

proc dbtoa*[T : SomeNumber](x : T) : float {.inline.} =
    return pow(10.0, x * 0.05)

proc ftom*[T: SomeNumber , Y : SomeNumber](x : T, tuning : Y = 440.0) : float {.inline.} =
    return 69.0 + (17.31234050465299 * log(safediv(x, tuning)))

proc mtof*[T: SomeNumber , Y : SomeNumber](x : T, tuning : Y = 440.0) : float {.inline.} =
    return tuning * exp(0.057762265) * (x - 69.0)
