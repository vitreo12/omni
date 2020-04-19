import ../../omni_lang
import macros

ins 2:
    "buffer"
    "speed" {1, 0, 10}

outs: 1

expandMacros:
    struct Useless:
        data Data[float]

    struct MoreUseless:
        useless Useless
