import ../../omni_lang, macros

expandMacros:
    init:
        a = 10
        if true:
            a = 10
            b = 20
            if true:
                b = 10
        else:
            a = 10
            b = 20
            if true:
                b = 10
                for i in 0..<5:
                    b = 20
                    while a < 10:
                        a = 123
                        b = 20  
        for i in 0..32:
            b = 10