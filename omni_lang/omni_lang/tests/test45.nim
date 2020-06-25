import ../../omni_lang, macros

#It should only look at these two modules, not all the omni_lang ones!
#that will cause problems
require "test45Import1.nim", "test45Import2.nim"

struct Ah:
    a

expandMacros:
    init:
        a = test45Import1.Something(0, 1, 2)
        print(test45Import1.someFunc())

        b = test45Import2.Something()
        print(test45Import2.someFunc())

        c = Data(1)

        print(sin(0.23))

        print(c.read(0))