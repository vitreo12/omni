import ../../../omni_lang, macros

expandMacros:
    struct Something[T]:
        a T

    init:
        a = Something(9.23)
        b = Data()
        c = Delay()