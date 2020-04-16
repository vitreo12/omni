type
    Data_obj[T] = object
        data : T
        size_X_chans : int
    
    Data[T] = ptr Data_obj[T]

    Buffer_obj = object
        a : float

    Buffer = ptr Buffer_obj

    A_obj = object
        buf  : Buffer
        data : Data[Data[Buffer]]

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

type
    DataRegister[T] = object
        datas : UncheckedArray[Data[T]]























proc registerChild[T](dataRegister : ptr DataRegister, data : Data[T]) : void =
    discard

proc A_inner_init(obj : typedesc[A], buf : Buffer, data : Data[Data[Buffer]]) : A =
    discard

proc registerData(obj : A, dataRegister = ptr DataRegister) : void =
    dataRegister.registerChild(obj.data)
    for i in (0..obj.data.size_X_chans-1):
        dataRegister.registerChild(obj.data[i])

template new(obj : typedesc[A], buf : Buffer, data : Data[Data[Buffer]]) : A =
    discard

proc B_inner_init(obj : typedesc[B], a : A, buf : Buffer, data : Data[A]) : B =
    discard

proc registerData(obj : B, dataRegister = ptr DataRegister) : void =
    dataRegister.registerChild(obj.data)
    for i in (0..obj.data.size_X_chans-1):
        let element = obj.data[i]
        element.registerData(dataRegister)

template new(obj : typedesc[B], a : A, buf : Buffer, data : Data[A]) : B =
    discard

proc C_inner_init(obj : typedesc[C], b : Data[B], bb : B) : C =
    discard

proc registerData(obj : C, dataRegister = ptr DataRegister) : void =
    dataRegister.registerChild(obj.b)
    for i in (0..obj.b.size_X_chans-1):
        let element = b.data[i]
        element.registerData(dataRegister)

template new(obj : typedesc[C], b : Data[B], bb : B) : C =
    discard