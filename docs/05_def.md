---
layout: page
title: def
---

A `def` is a function. It's a way to structure *Omni* code with re-usable functions.

```
def mySum(a, b):
    return a + b

sample:
    out1 = mySum(in1, in2)
```

The types of the arguments and the return type of a `def` are inferred by the calling context. This means that the `def mySum` can be called on whatever type that supports the `+` operator.

```
x      = mySum(1, 2)      #returns an int, but x will change it to float
x2 int = mySum(1, 2)      #this will preserve the int
y      = mySum(1.0, 2.0)  #returns a float
z      = mySum(1, 2.0)    #returns a float
```

Types can be forced by appending the type to the argument name.

```
def myIntSum(a float, b float):
    return a + b
```

Default values can be simply added with a `=` operator.

```
def mySum(a = 0, b = 0):
    return a + b
```

The return type can also be forced with either of these two syntaxes:

```
def mySum(a = 0, b = 0) float:
    return a + b

def myOtherSum(a = 0, b = 0) -> float:
    return a + b
```

Also, `def` supports the use of generics. Generics in *Omni* can only represent number types (`int, int32, int64, float, float32, float64`). As with variable declaration, generic `defs` default their types to `floats`. To act otherwise, this must explicitly be called

```
def myGenericSum[T, Y](a T, b Y):
    return a + b

init:
    print myGenericSum(1, 2)             #[float, float] -> float
    print myGenericSum[int, int](1, 2)   #[int, int] -> int
    print myGenericSum[int, float](1, 2) #[int, float] -> float
```

When using a recursive `def`, the return type must always be specified. It can also just be a generic type.

```
params: 
    x

def factorial(x) float:
    if x <= 1: return 1.0
    return x * factorial(x - 1)

init:
    print factorial(x)

sample:
    out1 = 0.0
```

When passing `structs` (more on them in the next section) to a `def`, they are passed by reference, meaning that they can be accessed and their values can be modified in place.

```
struct Vector:
    x; y; z

def updateVec(vec, x, y, z):
    vec.x = x
    vec.y = y
    vec.z = z

init:
    vec = Vector()
    vec.updateVec(10, 20, 30)
    print vec.x
    print vec.y
    print vec.z
```

<br>

## [Next: 06 - Custom types: struct](06_struct.md)