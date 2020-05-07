import ../../omni_lang
import macros

struct Vec[X, Y, Z]:
    x X
    y Y
    z Z

def setValues[X, Y, Z](vec Vec, x X, y Y, z Z):
    vec.x = x
    vec.y = y
    vec.z = z

def setValuesAlternative(vec, x, y, z):
    vec.x = x
    vec.y = y
    vec.z = z

ins 1
outs 1

init:
    myVec1 = Vec(0.0, 0.0, 0.0) #Vec[float, float, float]
    myVec2 = Vec(0, 0, 0)       #Vec[int, int, int]
    myVec3 = Vec(0.0, 0, 0.0)   #Vec[float, int, float]

    myVec1.setValues(1.0, 2.0, 3.0)

    print(myVec1.x)
    print(myVec1.y)
    print(myVec1.z)

    myVec2.setValuesAlternative(1, 2.0, 3)

    print(myVec2.x)
    print(myVec2.y)
    print(myVec2.z)
    
sample:
    out1 = 0.0