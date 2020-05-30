import ../../omni_lang, macros

struct Ah:
    a

struct Eh:
    data Data[Ah]

expandMacros:
    init:
        data = Data[Eh](10)
        for eh in data:
            eh = Eh(Data[Ah](10))
            for ah in eh.data:
                ah = Ah()