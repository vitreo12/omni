import ../../omni_lang
import macros

ins 1
outs 1

expandMacros:
    struct SomethingElse:
        phase float

    struct Something[T, Y]:
        a Signal
        b Data[T]
        c Y
        d SomethingElse

    init:
        a = 0
        b = Data.new(100)
        c = 1
        d = SomethingElse.new(0.5)

        something = Something.new(a, b, c, d)