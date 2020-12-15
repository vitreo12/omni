import ../../omni_lang
import macros except params

omni_debug_macros:
    params:
        freq {440, 1, 22000}
        amp

    #[ buffers:
        buf1 "def"
        buf2
        buf3 "def1" ]#
 
    init:
        a = freq

    sample:
        out1 = freq