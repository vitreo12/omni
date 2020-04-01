import ../../omni_lang
import macros

ins 1
outs 1

expandMacros:

    struct SomethingElse[T]:
        g : T
        a : T

    struct Something[T, Y, Z]:
        a T
        g Data[Z]
        b SomethingElse[Y]

    struct Bah:
        phase float

    struct Dejfff:
        data Data[float]

    def something():
        return 0.5

    init:
        #c = SomethingElse.new(1, 2)
        a = Something.new(1, Data.new(10), SomethingElse.new(1.34, 14.2))
        bah = Bah.new(10.32)

        build a

    sample:
        out1 = something()