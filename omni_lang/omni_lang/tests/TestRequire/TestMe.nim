import ../../../omni_lang, macros

require ImportMe

struct Bubu[T]:
    a T

def something(bubu):
    return bubu.a

expandMacros:
    init:
        bubu = Bubu()
        bubu2 = Bubu[float]()
        bubu3 = TestMe.Bubu.new()
        bubu4 = Bubu.new()
        bubu5 = Bubu[float].new()
        bubu6 = TestMe.Bubu[float].new()
        bubu7 = TestMe.Bubu[float]()

        importme = ImportMe()
        importme2 = ImportMe[float]()
        importme3 = ImportMe.ImportMe.new()
        importme4 = ImportMe.new()
        importme5 = ImportMe[float].new()
        importme6 = ImportMe.ImportMe[float].new()
        importme7 = ImportMe.ImportMe[float]()

        importmetoo = ImportMe.ImportMeToo()
        importmetoo2 = ImportMe.ImportMeToo[float]()
        #[ importmetoo3 = ImportMe.ImportMeToo.new()
        importmetoo4 = ImportMe.ImportMeToo[float].new()
        importmetoo5 = ImportMe.ImportMeToo[float]() ]#

        print(bubu.something())

    sample:
        out1 = bubu.a