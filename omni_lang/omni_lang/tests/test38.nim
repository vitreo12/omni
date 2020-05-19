import ../../omni_lang, macros

struct Ah[T]:
    a T

struct Bh[T]:
    a Ah[T]

expandMacros:
    init:
        bh = Bh(Ah[int]())