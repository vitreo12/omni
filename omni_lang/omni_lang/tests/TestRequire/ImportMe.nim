import ../../../omni_lang, macros

struct ImportMe:
    a

def something():
    return 0

#expandMacros:
def blah(a):
    print("blah")

def blah(a ImportMe):
    print("blah - ImportMe")