import ../../../omni_lang, macros

#[ use Ah:
    ImportMeImportMe as ImportMeImportMe1
    something as something2 ]#

#expandMacros:
struct ImportMe[T]:
    a T

#[ def something(a ImportMe):
    print("something - ImportMe")

def something(a):
    print("something - auto")

def something():
    print("something") ]#

#[ def something[T](a T):
    print("something - Generics") ]#

expandMacros:
    def blah[T](a ImportMe, b T = 0, c ImportMe[T], d ImportMe):
        print("blah - ImportMe")

    def blah[T](a ImportMe[T]):
        print("blah - ImportMe")

    #[ def blah(a):
        print("blah - ImportMe") ]#

    #[ def blah(a ImportMe[float]):
        print("blah - ImportMe") ]#

#[ def blah(a):
    print("blah - auto")

def blah():
    print("blah") ]#

#[ init:
    a = ImportMe()
    a.blah() ]#