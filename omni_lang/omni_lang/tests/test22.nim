import ../../omni_lang

ins 1
outs 1

struct Bubu[T]:
    a : T

struct Something:
    data Data[Data[Bubu[float]]]

init:
    a = Data.new()
    b = Data.new(dataType=Data[Data[float]])
    c = Data.new(dataType=Data[Data[Bubu[float]]])
    bubu = Bubu.new(0.5)
    something = Something.new(Data.new(dataType=Data[Bubu[float]]))

sample:
    out1 = in1