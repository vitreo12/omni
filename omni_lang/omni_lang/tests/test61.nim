import ../../omni_lang, macros

expandMacros:
    params 2:
        freq {440, 1, 22000}
        amp  {1, 0, 1}

#[ sample:
    out1 = freq * amp ]#