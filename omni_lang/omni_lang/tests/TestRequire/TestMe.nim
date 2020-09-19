import ../../../omni_lang, macros

#[ require:
    ImportMe
    ImportMeCopy ]#

require "ImportMe.nim"

#[ struct Bubu[T]:
    a T

def something(bubu):
    return bubu.a ]#

expandMacros:
    init:
        #[ bubu = Bubu()
        bubu2 = Bubu[float]()
        bubu3 = TestMe.Bubu.new()
        bubu4 = Bubu.new()
        bubu5 = Bubu[float].new()
        bubu6 = TestMe.Bubu[float].new()
        bubu7 = TestMe.Bubu[float]() ]#

        #[ importme = ImportMe.ImportMe()
        importme2 = ImportMe.ImportMe[float]()
        importme3 = ImportMe.ImportMe.new()
        importme4 = ImportMe.ImportMe.new()
        importme5 = ImportMe.ImportMe[float].new()
        importme6 = ImportMe.ImportMe[float].new()
        importme7 = ImportMe.ImportMe[float]() ]#

        importme = newImportMe()

        #[ importmecopy = ImportMeCopy.ImportMe()
        importmecopy2 = ImportMeCopy.ImportMe[float]()
        importmecopy3 = ImportMeCopy.ImportMe.new()
        importmecopy4 = ImportMeCopy.ImportMe.new()
        importmecopy5 = ImportMeCopy.ImportMe[float].new()
        importmecopy6 = ImportMeCopy.ImportMe[float].new()
        importmecopy7 = ImportMeCopy.ImportMe[float]() ]#

        #[ importmetoo = ImportMe.ImportMeToo()
        importmetoo2 = ImportMe.ImportMeToo[float]()
        importmetoo3 = ImportMe.ImportMeToo.new()
        importmetoo4 = ImportMe.ImportMeToo[float].new()
        importmetoo5 = ImportMe.ImportMeToo[float]() ]#

        #print(bubu.something())

    sample:
        out1 = bubu.a