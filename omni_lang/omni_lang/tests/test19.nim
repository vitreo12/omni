import ../../omni_lang
import macros

ins 1
outs 1

#Dummy test
struct Buffer:
    a

#WHAT ABOUT IF SOMETHING ELSE HAS BUFFER / DATA ????
struct SomethingElse:
    x
    k Buffer

struct AhAh[T]:
    x T
    data Data[SomethingElse]
    b Buffer

struct Something[T, Y]:
    x T
    ahah AhAh[Y]

expandMacros:
    init:
        data = Data.new(10, dataType=SomethingElse)
        ahah = Ahah.new(0.5, data, Buffer.new(1))
        something = Something.new(1, ahah)

        #This buffer won't be picked!!!
        data[0] = SomethingElse.new(0.5, Buffer.new(1))
        
sample:
    out1 = in1