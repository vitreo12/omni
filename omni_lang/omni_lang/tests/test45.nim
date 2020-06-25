import ../../omni_lang, macros

require "test45Import1.nim", "test45Import2.nim"

struct Ah:
    a

expandMacros:
    init:
        a = test45Import1.Something(0, 1, 2)
        print(test45Import1.someFunc())