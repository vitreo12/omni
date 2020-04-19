import ../../omni_lang
import macros

ins 1
outs 1

expandMacros:
    struct Bibi:
        a float
        data Data[Data[float]]

    struct Buffer:
        a float

    struct Bubu[T]:
        a T

    struct Something:
        data Data[Data[Bubu[float]]]


    init:
        a = Data.new()
        b = Data.new(dataType=Data[Data[float]])
        c = Data.new(dataType=Data[Data[Bubu[float]]])
        bubu = Bubu.new(0.5)
        something = Something.new(Data.new(dataType=Data[Bubu[float]]))
        bibi = Data.new(dataType=Data[Data[Bibi]])

        z = Buffer.new(1)
        k = Data.new(dataType=Buffer)
        m = Data.new(dataType=Bibi)

sample:
    out1 = in1

