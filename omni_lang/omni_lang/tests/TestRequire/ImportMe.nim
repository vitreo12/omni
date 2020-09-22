import ../../../omni_lang, macros

struct ImportMe:
    a

#expandMacros:
def something(a ImportMe):
    print("something- ImportMe")

def something(a):
    print("something")

def blah(a ImportMe):
    print("blah - ImportMe")

def blah(a):
    print("blah")

#[ def blah(a ImportMe):
    print("blah - ImportMe") ]#

#[ init:
    a = ImportMe()
    a.something()
    something(10)
    a.blah()
    blah(10) ]#