import ../../omni_lang, macros
#[ 
struct Ciccio[T, Y]:
    a T
    b Y ]#

#expandMacros:
struct Ah[T]:
    data1 Data
    #data2 Data[T]
    #data3 Data[Data[Ciccio]]
    
    a T
    b

init:
    #ci = Ciccio()
    ah = Ah(Data(10))