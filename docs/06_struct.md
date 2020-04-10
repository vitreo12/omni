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
    myVec = Vector.new(0.0, 0.0, 0.0)

...
```

`structs` can only be created in the `init` block. To create a `struct`, use the in-built `new` method. It will take the elements of the struct as argument and initialize the struct for you.

```nim
ins:  1
outs: 1

struct Vector:
    x float
    y float
    z float

def newVec():
    return Vector.new(0.0, 0.0, 0.0)

init:
    myVec = newVec()

```

`structs`, just like `defs`, support generics. Again, generics are here to be intended as only some kind of number.

```nim
struct Vector[X, Y, Z]:
    x X
    y Y
    z Z

#No need to specify Vector[X, Y, Z]
def setValues[X, Y, Z](vec Vector, x X, y Y, z Z):
    vec.x = x
    vec.y = y
    vec.z = z

init:
    myVec1 = Vector.new(0.0, 0.0, 0.0) #Vector[float, float, float]
    myVec2 = Vector.new(0, 0, 0)       #Vector[int, int, int]
    myVec3 = Vector.new(0.0, 0, 0.0)   #Vector[float, int, float]

    #Alternative def calling syntax: obj.method(args...)
    myVec1.setValues(1.0, 2.0, 3.0)

    print(myVec1.x)
    print(myVec1.y)
    print(myVec1.z)

sample:
    out1 = myVec1.x * myVec1.y * myVec1.z
```