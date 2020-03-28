import ../../omni_lang
import macros

ins 1
outs 1

def something(a):
    return a * 0.5

def amp2db(ampVal):
    return log10(float(ampVal))

expandMacros:
    sample:
        #echo in1
        a = sin(1.0) / 10
        b = 10.3 mod 0.0
        c = a * 2
        out1 = amp2db(in1)