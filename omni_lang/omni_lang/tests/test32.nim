import ../../omni_lang
import macros

ins 1
outs 1

struct SomethingElse[T]:
    g : T
    a : T

struct Something[T, Y, Z]:
    a T
    g Data[Z]
    b SomethingElse[Y]

struct Bah:
    phase float

def allocInPerform():
    print("allocating in perform")
    #b = Bah(0.0)

init:
    bah = Bah(0.0)
    something = Something(0.5, Data(100), SomethingElse(1, 4))

    test = true

sample:
    if test:
        allocInPerform()
        test = false
        
    out1 = in1