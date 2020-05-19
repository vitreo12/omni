type
    Type1[T] = object
        a : T

    Type2[T] = object
        t1 : Type1[T]

proc struct_new_inner[T](obj : typedesc[Type1[T]], a : auto) : Type1[T] =
    return Type1[T](a : T(a))

template struct_new[T](obj : typedesc[Type1[T]], a : T = 0.0) : untyped =
    struct_new_inner(Type1[T], a)

proc struct_new_inner[T](obj : typedesc[Type2[T]], t1 : auto) : Type2[T] =
    return Type2[T](t1 : t1)

template struct_new[T](obj : typedesc[Type2[T]], t1 : Type1[T]) : untyped =
    struct_new_inner(Type2[T], t1)

let t1 = Type1.struct_new()
let t2 = Type2.struct_new(t1)

echo typeof t1
echo typeof t2

let t11 = Type1.struct_new(0)      #However, I want this to still return float...
let t12 = Type1.struct_new(0.0)
let t13 = Type1[int].struct_new(0)

echo typeof t11
echo typeof t12
echo typeof t13