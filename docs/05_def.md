---
layout: page
title: def
---

A `def` is a function. It's a way to structure omni code with re-usable blocks.

```nim
ins:  2
outs: 1

def mySum(a, b):
    return a + b

sample:
    out1 = mySum(in1, in2)
```

The types of the arguments and the return type of a `def` are inferred by the calling context. This means that the `def mySum` can be called on whatever type that supports the `+` operator.

```nim
x = mySum(1, 2)     #returns an int
y = mySum(1.0, 2.0) #returns a float
z = mySum(1, 2.0)   #returns a float
```

Types can be inforced by appending the type to the argument name.

```nim
def myIntSum(a int, b int):
    return a + b
```

Also, `def` supports the use of generics. Generics in omni can only represent number types (`int, int32, int64, float, float32, float64`).

```nim
def myGenericSum[T, Y](a T, b Y):
    return a + b
```

Default values can be simply added with a `=` operator.

```nim
def mySum(a = 0, b = 0):
    return a + b
```

The return type can also be enforced with either of these two syntaxes:

```nim
def mySum(a = 0, b = 0) int:
    return a + b

def myOtherSum(a = 0, b = 0) -> int:
    return a + b
```

Return type can of course be a generic type:

```nim
def mySum[T, Y](a T = 0, b Y = 0) T:
    return a + b
```

<br>

## [Next: 06 - Custom types: struct](06_struct.md)