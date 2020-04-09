# struct

A `struct` is a way to create custom object with custom fields. 

```nim
ins:  1
outs: 1

struct Vec:
    x float
    y float
    z float

init:
    myVec = Vec.new(0.0, 0.0, 0.0)

...
```

`structs` can only be created in the `init` block.

`structs`, just like `defs`, support generics. Again, generics are here to be intended as only some kind of number.

```nim
struct Vec[X, Y, Z]:
    x X
    y Y
    z Z

def setValues[X, Y, Z](vec Vec, x X, y Y, z Z):
    vec.x = x
    vec.y = y
    vec.z = z

init:
    myVec1 = Vec.new(0.0, 0.0, 0.0) #Vec[float, float, float]
    myVec2 = Vec.new(0, 0, 0)       #Vec[int, int, int]
    myVec3 = Vec.new(0.0, 0, 0.0)   #Vec[float, int, float]

```



generics