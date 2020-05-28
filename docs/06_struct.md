---
layout: page
title: struct
---

A `struct` is a way to create custom object with custom fields. 

```nim
ins:  1
outs: 1

struct Vector:
    x float
    y float
    z float

init:
    myVec = Vector(0.0, 0.0, 0.0)
```

`structs` can only be created in the `init` block. To create a `struct`, simply call the name of the `struct`. It will take the elements of the struct as arguments and initialize the struct for you.
An alternative constructor syntax, is by using the `new` keyword.

**_NOTE_:** If no type is defined for a field, it's defaulted to `float`.

**_NOTE_:** For number types (`int`, `int32`, `int64`, `float` / `sig`, `float32` / `sig32`, `float64` / `sig64`) a default value of `0` is given to the constructor arguments.

```nim
ins:  1
outs: 1

struct Vector:
    x float
    y float
    z float

init:
    #Four different ways of constructing a Vector
    myVec1 = Vector(0.0, 0.0, 0.0)
    myVec2 = Vector()
    myVec3 = Vector.new(0.0, 0.0, 0.0)
    myVec4 = Vector.new()
```

`structs`, just like `defs`, support generics. Generics, as of now, only support number types.

```nim
struct Vector[X, Y, Z]:
    x X
    y Y
    z Z

#Enforce argument types
def setValues[X, Y, Z](vec Vector, x X, y Y, z Z):
    vec.x = x
    vec.y = y
    vec.z = z

#This def will act equivalently as the previous one:
#the types of vec, x, y, z will be inferred.
#Of course, if this method is called on a struct that doesn't have
#the x/y/z fields, this will throw an error.
def setValuesAlternative(vec, x, y, z):
    vec.x = x
    vec.y = y
    vec.z = z

init:
    #If generics are not specified, they are 
    #defaulted to 'signal' (which is identical to 'float')
    myVec1 = Vector() # == Vector[signal, signal, signal]
    myVec2 = Vector[int, int, int]()
    myVec3 = Vector[float, int, float]()

    myVec1.setValues(1.0, 2.0, 3.0)

    print(myVec1.x)
    print(myVec1.y)
    print(myVec1.z)

    myVec2.setValuesAlternative(1, 2, 3)

    print(myVec2.x)
    print(myVec2.y)
    print(myVec2.z)

    myVec3.setValuesAlternative(1, 2.0, 3)

    print(myVec3.x)
    print(myVec3.y)
    print(myVec3.z)
```

`structs` can store other `structs`, allowing the creation of complex data structures.

```nim
ins  1
outs 1

struct FirstStruct:
    data Data[float]

struct SecondStruct:
    x FirstStruct

init:
    firstStruct  = FirstStruct(Data(10))       #create a FirstStruct
    secondStruct = SecondStruct(firstStruct)   #create a SecondStruct, using the previously declared firstStruct
```

When not otherwise specified, `structs` with generics will default to `float`:

```nim
struct MyStruct:
    data Data       #defaulted to Data[float]

init:
    data = Data(10) #Data(10) defaults to Data[float](10)
    myStruct = MyStruct(data)  
```

<br>

## [Next: 07 - Memory allocation: Data](07_data.md)