import ../../omni_lang, macros

expandMacros:
    def bubu(SOMETHING = 2):
        loop SOMETHING i:
            print i

    init:
        bubu(10)