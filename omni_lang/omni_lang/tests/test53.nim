import ../../omni_lang, macros

struct Buh:
    a Data[int]

expandMacros:
    init:
        b = Buh new Data[int](10)
        c = Data[Buh].new(10)
        k = new Data[int] 10
        z = Data[int32] 10