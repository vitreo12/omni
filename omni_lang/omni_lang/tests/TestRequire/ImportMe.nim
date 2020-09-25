import ../../../omni_lang, macros

use Ah:
    ImportMeImportMe as ImportMeImportMe1
    something as something2

struct ImportMe[T]:
    a T

def something(a ImportMe):
    print("something - ImportMe")

def something(a):
    print("something - auto")

def something():
    print("something")

#[ def something[T](a T):
    print("something - Generics") ]#

def blah(a ImportMe):
    print("blah - ImportMe")

#[ def blah(a):
    print("blah - auto")

def blah():
    print("blah") ]#

#[ init:
    a = ImportMe() ]#