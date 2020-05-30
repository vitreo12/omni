import ../../omni_lang

inputs 1
outputs 1

struct Phasor:
    a

init:
    a = 10
    b = Phasor()

sample:
    outs[0] = ins[0]