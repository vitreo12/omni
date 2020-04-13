import ../../omni_lang
import macros

ins 1
outs 1

expandMacros:
    init:
        a sig
        z Data[float] = Data.new(100)
        k = Data.new(100)
        #p Data[float]
        m array[100, int]
        a = 10
        print(a)
