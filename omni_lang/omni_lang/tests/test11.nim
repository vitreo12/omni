import ../../omni_lang

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
    b = Bah.new(0.0)

init:
    bah = Bah.new(0.0)
    something = Something.new(0.5, Data.new(100), SomethingElse.new(1, 4))
    MYCONST = Bah.new(1.23)
    test = true

sample:
    if test:
        allocInPerform()
        test = false
        
    out1 = in1