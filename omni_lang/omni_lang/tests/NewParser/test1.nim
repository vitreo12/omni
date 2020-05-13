import ../../../omni_lang, macros

ins 1
outs 1

struct Test:
    a
    data Data[float]

struct Bah:
    tst Test


expandMacros:
    def something():
        return Test(Test(data=Data(10)).a, data=Data(10))


init:
    #[ a = 10
    b float = 0.5
    c float

    test = Test(data=Data(10))
    test.a = 0.5
    test.data[0] = 0.5

    bah = Bah(tst=Test(0.5, Data(10))) ]#
    print(Test(Test(data=Data(10)).a, data=Data(10)).a)

    a = ins[0]

    c = something()
    d = something()

    c.a = 0.23

expandMacros:
    sample:
        outs[0] = ins[a]
        c.a = 0.3
        c = d