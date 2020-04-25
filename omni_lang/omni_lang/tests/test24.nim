import ../../omni_lang
import macros

ins 1
outs 1

struct Bh:
    x

struct Ah:
    x
    y
    z
    bh Bh

def buh():
    ah = 0.5
    return ah

def something(a):
    return a.x

expandMacros:
    init:
        ah = Ah(bh=Bh(x=1))

        print(ah.something())