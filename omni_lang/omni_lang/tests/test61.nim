import ../../omni_lang, macros

expandMacros:
    ins 2: one; two

#[ params 2:
    freq; amp

sample:
    out1 = freq * amp ]#

sample:
    out1 = one