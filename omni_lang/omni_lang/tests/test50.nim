import ../../omni_lang, macros

expandMacros:
    def blah():
        c = (0.5, 2)
        return c

    def bluh():
        c = Data(10)
        return c

    init:
        a = blah()
        d = bluh()
        print(a[0])

    sample:
        out1 = a[1]