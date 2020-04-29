import ../../omni_lang
import macros

ins 1
outs 1

expandMacros:
    struct Ahah:
        ahah signal64
        bhbh int
        chch

    struct SomethingElse[T]:
        phase T
        ahah Ahah

    struct Something[T, Y]:
        a sig
        b Data[T]
        c Y
        d SomethingElse[Y]

    init:
        a = 0
        b = Data.new(100)
        c = 1
        d = SomethingElse.new(0, Ahah.new(0, 0, 0))

        something = Something.new(a, b, c, d)

    def something(a):
        return a

    sample:
        out1 = something(0.3412312)