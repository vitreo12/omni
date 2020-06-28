import ../../omni_lang
import macros

expandMacros:
    init:
        a = Data(10, 2)

        a[0, 0] = 1
        a[1, 0] = 1

        for chan, i, entry in a:
            c = entry

        

sample:
    out1 = in1