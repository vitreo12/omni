import ../../../omni_lang, macros

require ImportMeToo

#struct ImportMeToo[T]:
#    a T

#struct ImportMeToo:
#    a

def something():
    return 0

#expandMacros:
struct ImportMe[T]:
    a T
    b ImportMeToo

def newImportMe():
    b = ImportMeToo()
    return ImportMe(0, b)