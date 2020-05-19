import ../../omni_lang, macros

struct Buh[T, Y]:
    a T
    b Y

expandMacros:
    struct Ah[T]:
        data1 Data
        data2 Data[Data[T]]
        data3 Data[Data]
        a T
        buh Buh
        k Data[Data[Data[Buh]]]
        g Buh[T, T]