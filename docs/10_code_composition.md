## Code composition

Omni encourages the re-use of code. Portions of code, especially the declaration of `structs` and `defs`, can easily be packaged in individual source files that can be included into different projects thanks to the `include` statement.

### *Vector.omni*:
```nim
struct Vector[X, Y, Z]:
    x X
    y Y
    z Z

def setValues[X, Y, Z](vec Vector, x X, y Y, z Z):
    vec.x = x
    vec.y = y
    vec.z = z
```

### *VecTest.omni*:
```nim
include "Vector.omni"

ins:  3
outs: 1

init:
    myVec = Vector.new(0.0, 0.0, 0.0)

sample:
    myVec.setValues(in1, in2, in3)
    out1 = myVec.x * myVec.y * myVec.z
```