import ../../omni_lang
import macros

ins  3
outs 1

struct Vector:
    x sig
    y sig
    z sig

expandMacros:
    def newNewVector():
        return Vector()

    def newVector():
        return newNewVector()

init:
    dataLength = 100
    data = Data(dataLength, dataType=Vector)
    
    for i in (0..dataLength-1):
        data[i] = newVector()
 
sample:
    for i in (0..dataLength-1):
        vector = data[i]
        vector.x = in1
        vector.y = in2
        vector.z = in3
    
    #b = newVector()

    out1 = in1 * in2 * in3