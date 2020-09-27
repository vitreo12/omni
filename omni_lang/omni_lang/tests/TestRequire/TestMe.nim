import ../../../omni_lang, macros

expandMacros:
    use ImportMe:
        ImportMe as ImportMe1
        ImportMeImportMe1 as ImportMeImportMe
        something as something1
        Ah as Ah1
        Bubu as Bubu1
        blah as blah1

#expandMacros:
#[ struct Bubu:
    a ImportMe1
    b ImportMeImportMe

def something(a ImportMe1):
    return a.a

def something(a ImportMeImportMe):
    return a.a ]#

expandMacros:
    init:
        h=Bubu1[int](0, ImportMeImportMe())
        a = ImportMe1[float, int, float](a=10, h=h, c=Data[Data[Data[int]]]())
        a.blah1()

    #blah1(10)

    #[ a.blah1()
    blah1(10)
    blah1()

    a.something1()
    something1(1)
    something1() ]#