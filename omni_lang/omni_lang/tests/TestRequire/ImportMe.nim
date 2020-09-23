import ../../../omni_lang

use Ah:
    ImportMeImportMe as ImportMeImportMe1

struct ImportMe:
    a

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

def blah(a):
    print("blah - auto")

def blah():
    print("blah")

#[ init:
    a = ImportMe()
    a.something()
    something(10)
    a.blah()
    blah(10) ]#