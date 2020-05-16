import ../../omni_lang, macros

struct Buh[T, Y]:
    a T
    c Y

struct Bb:
    a

struct Bubbu:
    bb Bb

struct Gamma:
    bb Bb

expandMacros:
    init:
        #[ p = Data[int](1)
        l = Data[Data[Buh[int, float]]].new(10)
        f = Buh[int, float].new()
        d = Data(10)
        b = Buh[int, float](0, 0)
        k = Data[Buh[int, float]](10)
        z = Buh(1, 2.32) ]#
        #[ j = Data(1)
        m = Buh()
        h = Bb()

        amma = Gamma(h) ]#
       #[  bubbu = Bubbu(Bb())
        sin = Bb()
        f = Buh[int, float]()
        l = Buh() ]#

        baba = Buh.new()

        #gamma = Gamma(h)

        for index in 0..10:
            p = 10

        a = 10

sample:
    a = 12
    out1 = a