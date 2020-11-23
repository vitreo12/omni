import ../../omni_lang
import macros except params

expandMacros:
    params:
        freq {440, 1, 22000}
        amp

    buffers:
        buf
        
#[ 
init:
    a = freq

sample:
    out1 = a ]#