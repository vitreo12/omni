import ../../../omni_lang, macros

import ImportMe
import ImportMeToo

struct Bubu:
    a

def something(bubu):
    return bubu.a

expandMacros:
    init:
        importme1 = ImportMe.ImportMe()

        importme2 = ImportMe.ImportMe[int]()
        
        #importme2 = ImportMe.ImportMe(int(1))

        data1 = Data[Data[int]].new()

        data2 = Data[Data[Data[Bubu]]](1)

        a = ImportMe.something()
        
        bubu = Bubu()
        
        print(bubu.something())