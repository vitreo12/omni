import ../../../omni_lang, macros

expandMacros:
    require "ImportMe.nim", "ImportMeToo.nim"

    init:
        a = ImportMe()
        b = ImportMeToo(c = a)

        c = ImportMeToo.new(c = a)

    sample:
        out1 = in1
