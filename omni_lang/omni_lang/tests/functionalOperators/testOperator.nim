import ../../../omni_lang, macros

macro operator(which : untyped, args : varargs[untyped]) : untyped =
    return quote do:
        `which`(`args`)

#Works with custom def operators too!
def myOperator(one, two):
    return (one + two) * (one + two)

init:
    print operator(`+`, 2, 3)
    print operator(`*`, 2, 3)
    print operator(`pow`, 2, 3)
    print operator(`myOperator`, 2, 3)

sample:
    out1 = 0.0
