import ../../omni_lang
import macros

ins 1
outs 1


expandMacros:
    struct ZZ[T]:
        a T

    struct A:
        data Data[Data[ZZ[float]]]

    struct B:
        a A
        data Data[A]

    struct C:
        b Data[B]
        bb B

    init:
        dataB = Data.new(10, dataType=B)
        a  = A.new(Data.new(10, dataType=Data[ZZ[float]]))
        bb = B.new(a,Data.new(10, dataType=A))
        c  = C.new(dataB, bb)

        build:
            c

    sample:
        out1 = in1