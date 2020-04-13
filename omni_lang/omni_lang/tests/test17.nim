import ../../omni_lang
import macros

ins 1
outs 1

expandMacros:
    init:
        a = 0.0
        b = 2
        a = b
        
        c = Data.new(100)
        something = c

        #out1 = 0
    
    sample:
        out1 = b
        #something = c