import ../../omni_lang
import macros
import math

expandMacros:
    ins 1
    outs 1

    def someAlloc(a=0):
        a = Data.new(10)
        return 0.5

    def someMoreAlloc(data):
        data = data
        return 0.5

    def someSine[T](a T) T:
        return sin(a)

    init:
        a = someAlloc()
        b = Data.new(10)
        c = someMoreAlloc(Data.new(10))

        build a, c

    sample:
        out1 = in1
        #a = 0.213