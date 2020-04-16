import ../../omni_lang
import macros

struct Buffer:
    a

struct A:
    buf Buffer
    data Data[Data[Buffer]]

struct B:
    a A
    buf Buffer
    data Data[A]

struct C:
    b Data[B]
    bb B

init:
    dataB = Data.new(10, dataType=B)
    c = C.new(dataB, B.new(A.new(Buffer.new(1), Data.new(10, dataType=Data[Buffer])), Buffer.new(1), Data.new(10, dataType=A)))
    
    #c_let.b[..]
    #           .data[..]
    #                    .data[..][..]
    #           .a
    #             .data[..][..]

    #[ for i in (0..dataB.size-1):
        data = Data.new(10, dataType=Data[float])
        for y in (0..data.size-1):
            data[y] = Data.new(10)
        a = A.new(Buffer.new(1), data)
        b = B.new(a, Buffer.new(1), Data.new(10, dataType=A))
        c.b[i] = b ]#
    
    build:
        c