import ../../omni_lang, macros

ins 1
outs 1

struct Bubu:
    x

init:
    data = Data(10, dataType=Bubu)

    for i in 0..9:
        data[i] = Bubu(i)

    for entry in data:
        print(entry.x)

sample:
    out1 = in1