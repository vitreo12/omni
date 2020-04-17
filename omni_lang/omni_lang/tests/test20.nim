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


proc checkObjDatasValidity(obj : A) : bool =
    result = true
    if not obj.data.checkDataValidity():
        result = false

    #if Data[Data[Data[...]]]
    for i1 in (0..obj.data.size-1):
        let entry1 = obj.data[i1]
        if not checkDataValidity(entry1):
            result = false
            break

proc checkObjDatasValidity(obj : B) : bool =
    result = true
    if not obj.data.checkDataValidity():
        result = false

    if not obj.a.checkObjDatasValidity():
        return false

    for i1 in (0..obj.data.size-1):
        let entry1 = obj.data[i1]
        if not checkObjDatasValidity(entry1):
            result = false
            break

proc checkObjDatasValidity(obj : C) : bool =
    result = true
    if not obj.b.checkDataValidity():
        result = false

    for i1 in (0..obj.b.size-1):
        let entry1 = obj.b[i1]
        if not entry1.checkObjDatasValidity():
            return false

    if not obj.bb.checkObjDatasValidity():
        result = false

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
    
    discard checkObjDatasValidity(c)

    build:
        c