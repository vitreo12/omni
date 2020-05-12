import ../../../omni_lang, macros

ins 1
outs 1

struct Test:
    a
    data Data[float]

struct Bah:
    tst Test

expandMacros:
    init:
        #[ a = 10
        b float = 0.5
        c float

        test = Test(data=Data(10))
        test.a = 0.5
        test.data[0] = 0.5

        bah = Bah(tst=Test(0.5, Data(10))) ]#
        print(Test(data=Data(10)).a)