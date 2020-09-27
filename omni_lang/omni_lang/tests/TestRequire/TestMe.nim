import ../../../omni_lang, macros

expandMacros:
    use ImportMe:
        #[ ImportMe as ImportMe1
        ImportMeImportMe1 as ImportMeImportMe
        something as something1 ]#
        Ah as Ah1
        ImportMe as ImportMe1
        #blah as blah1

#expandMacros:
#[ struct Bubu:
    a ImportMe1
    b ImportMeImportMe

def something(a ImportMe1):
    return a.a

def something(a ImportMeImportMe):
    return a.a ]#

#expandMacros:
#init:
    #[ a = ImportMe1(0)
    a.blah1() ]#

    #blah1(10)

    #[ a.blah1()
    blah1(10)
    blah1()

    a.something1()
    something1(1)
    something1() ]#