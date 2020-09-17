import ../../../omni_lang, macros

import ImportMe
import ImportMeToo

struct Bubu:
    a

def something(bubu):
    return bubu.a

expandMacros:
    init:
        a = ImportMe.something()
        
        bubu = Bubu()
        
        print(bubu.something())