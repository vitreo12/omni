import ../../omni_lang, macros

struct Buh[T, Y]:
    a T
    c Y

init:
    p = Data[int](1)
    l = Data[Data[Buh[int, float]]].new(10)
    f = Buh[int, float].new()
    d = Data(10)
    b = Buh[int, float](0, 0)
    k = Data[Buh[int, float]](10)