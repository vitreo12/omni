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
x      = mySum(1, 2)      #returns an int, but x will change it to float
x2 int = mySum(1, 2)      #this will preserve the int
y      = mySum(1.0, 2.0)  #returns a float
z      = mySum(1, 2.0)    #returns a float
```

Types can be inforced by appending the type to the argument name.

```nim
def myIntSum(a float, b float):
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
def mySum(a = 0, b = 0) float:
    return a + b

def myOtherSum(a = 0, b = 0) -> float:
    return a + b
```

Return type can be a generic type, inferred from the types of the arguments:

```nim
def mySum[T, Y](a T = 0, b Y = 0) T:
    return a + b
```

When using a recursive `def`, the return type must always be specified. It can also just be a generic type.

```nim
ins 1
outs 1

def factorial(x) float:
    if x <= 1:
        return 1.0
    return x * factorial(x - 1)

init:
    x = factorial(in1)
    print(x)

sample:
    out1 = 0.0
```

When passing `structs` (more on them in the next section) to a `def`, they are passed by reference, meaning that they can be accessed and their values can be modified in place.

```nim
struct Vector:
    x; y; z

def updateVec(vec Vector, x, y, z):
    vec.x = x
    vec.y = y
    vec.z = z

init:
    vec = Vector()
    vec.updateVec(10, 20, 30)
    print(vec.x)
    print(vec.y)
    print(vec.z)
```

<br>

## [Next: 06 - Custom types: struct](06_struct.md)