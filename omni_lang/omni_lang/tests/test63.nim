import ../../omni_lang

struct Something:
    data Data

init:
    something = Something(Data())
    bubu := something.data

sample:
    out1 = bubu[0] 
