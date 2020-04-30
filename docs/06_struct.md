## struct

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
    myVec  = Vector(0.0, 0.0, 0.0)
    myVec2 = Vector()
    myVec3 = Vector.new(0.0, 0.0, 0.0)
    myVec4 = Vector.new()
```

`structs`, just like `defs`, support generics. Again, generics are here to be intended as only some kind of number.

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

#This def will act equivalently as the previous one. The types of vec, x, y, z will be inferred.
#Of course, if this method gets call to a struct that doesn't have the x/y/z fields, this will throw an error.
def setValuesAlternative(vec, x, y, z):
    vec.x = x
    vec.y = y
    vec.z = z

init:
    myVec1 = Vector(0.0, 0.0, 0.0) #Vector[float, float, float]
    myVec2 = Vector(0, 0, 0)       #Vector[int, int, int]
    myVec3 = Vector(0.0, 0, 0.0)   #Vector[float, int, float]

    myVec1.setValues(1.0, 2.0, 3.0)

    print(myVec1.x)
    print(myVec1.y)
    print(myVec1.z)

    myVec2.setValuesAlternative(1, 2, 3)

    print(myVec2.x)
    print(myVec2.y)
    print(myVec2.z)

sample:
    out1 = myVec1.x * myVec1.y * myVec1.z
```