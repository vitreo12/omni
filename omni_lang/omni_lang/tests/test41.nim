import ../../omni_lang, macros

struct Buh[T, Y]:
    a T
    b Y

#expandMacros:
struct Ah[T]:
    data1 Data
    data2 Data[Data[T]]
    data3 Data[Data]
    a T
    buh Buh
    k Data[Data[Data[Buh]]]
    h Data[Data[Data[sig]]]
    g Buh[T, T]
    l Buh[float, seq[int]]                  #should error out
    p Buh[Buh[T, T], Buh[Data[float], sig]] #should error out
    j Data[array[3, float]]                 #should error out