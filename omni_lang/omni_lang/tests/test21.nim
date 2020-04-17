import ../../omni_lang

type
    Buffer_obj = object
        a : float

    Buffer = ptr Buffer_obj

    Z_obj = object
        a : float

    Z = ptr Z_obj

    A_obj = object
        buf  : Buffer
        data : Data[Data[Data[Z]]]

    A = ptr A_obj

    B_obj = object
        a : A
        buf : Buffer
        data : Data[A]

    B = ptr B_obj

    C_obj = object
        b : Data[B]
        bb : B

    C = ptr C_obj


proc checkObjDatasValidity(obj : Z) : bool =
    result = true

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
        
        for i2 in (0..entry1.size-1):
            let entry2 = entry1[i2]
            if not checkDataValidity(entry2):
                result = false
                break
            
            for i3 in (0..entry2.size-1):
                let entry3 = entry2[i3]
                if not entry3.checkObjDatasValidity():
                    result = false
                    break


proc checkObjDatasValidity(obj : B) : bool =
    result = true
    if not obj.data.checkDataValidity():
        result = false

    for i1 in (0..obj.data.size-1):
        let entry1 = obj.data[i1]
        if not checkObjDatasValidity(entry1):
            result = false
            break


proc checkObjDatasValidity(obj : C) : bool =
    result = true
    if not obj.b.checkDataValidity():
        result = false

    if not obj.bb.checkObjDatasValidity():
        result = false
