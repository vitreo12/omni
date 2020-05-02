import ../../omni_lang
import macros

ins 1
outs 1

struct Bubu:
    x

expandMacros:
    init:
        data = Data(10, dataType=Bubu)

        #This doesn't work yet!
        #for index, entry in data.pairs:
        #    entry = Bubu(index)

        for i in 0..9:
            data[i] = Bubu(i)

        for entry in data:
            print(entry.x)

    sample:
        out1 = in1