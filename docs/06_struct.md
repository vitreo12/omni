---
layout: page
title: struct
---

A `struct` is a way to create custom object with custom fields. 

`structs` can only be declared in the `init` block. To declare a `struct`, simply call the name of the `struct`. It will take the elements of the struct as arguments and initialize the struct for you.

```
struct Vector:
    x float
    y float
    z float

init:
    myVec = Vector(0.0, 0.0, 0.0)
```

**_NOTE_:** If no type is defined for a field, it's defaulted to `float`.

**_NOTE_:** For number types (`int`, `int32`, `int64`, `float` / `sig`, `float32` / `sig32`, `float64` / `sig64`) a default value of `0` is given to the constructor arguments.

```
#When no types are specified for struct fields, they are defaulted to 'float'
struct Vector:
    x
    y
    z

init:
    #Six different ways of constructing a Vector
    myVec1 = Vector()
    myVec2 = Vector(0, 0, 0)
    myVec3 = Vector.new()
    myVec4 = Vector.new(0, 0, 0)
    myVec5 = new Vector
    myVec6 = new Vector(0, 0, 0)
```

`structs`, just like `defs`, support generics. Generics, as of now, only support number types.

```
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
    #If generics are not specified, they are defaulted to float
    myVec1 = Vector() # == Vector[float, float, float]()
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

```
struct FirstStruct:
    data Data[float]

struct SecondStruct:
    x FirstStruct

init:
    firstStruct  = FirstStruct(Data(10))       #create a FirstStruct
    secondStruct = SecondStruct(firstStruct)   #create a SecondStruct, using the previously declared firstStruct
```

When not otherwise specified, `structs` with generics will default to `float`:

```
struct MyStruct:
    data Data #defaulted to Data[float]

init:
    data = Data(10) #Data(10) defaults to Data[float](10)
    myStruct = MyStruct(data)  
```

It is possible to declare default values for a `struct`. These will be used when not providing the specific argument when declaring the `struct`:

```
struct Something[T]:
    a T
    
def newData[T](size):
    return Data[T](size)

struct SomethingElse[T]:
    a = 0.5
    b int = 3 
    something Something[T] #will call default Something[T]()
    something2   = Something[T](samplerate) #using a constructor: type is inferred
    data Data[T] = newData[T](100)          #not calling a constructor: must be explicit on the type!

init:
    #This will call the defaults provided   
    myVar = SomethingElse()

    #This will call the defaults except for something2, which is explicitly set
    myOtherVar = SomethingElse[int](something2 = Something[int](10)) 
```

*Omni* will always use the default constructor of a `struct` if not explicitly set otherwise:

```
struct Something:
    data Data
    delay Delay

init:
    something = Something() #automatically calls Data() and Delay() if user does not pass his own
```
<br>

## [Next: 07 - Memory allocation: Data](07_data.md)