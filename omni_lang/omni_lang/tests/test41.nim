import ../../omni_lang, macros

struct Ciccio[T, Y]:
    a T
    b Y

struct Ah[T]:
    data Data[Ciccio[sig,sig]]
    a T
    b

init:
    ci = Ciccio()
    ah = Ah(Data(10))