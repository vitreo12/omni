import ../../../omni_lang, macros

require "ImportMe.nim", "ImportMeToo.nim"

init:
    a = ImportMe()
    b = ImportMeToo(c = a)

    c = ImportMeToo.new()

sample:
    out1 = in1
