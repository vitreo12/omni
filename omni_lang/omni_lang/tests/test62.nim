import macros except params
import ../../omni_lang

expandMacros:
    ins 2:
        uaua 440
        ueue

    params:
        freq {440, 1, 22000}
        amp
        buf Buffer

init:
    a = freq

sample:
    out1 = a