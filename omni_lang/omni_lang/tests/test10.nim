import ../../omni_lang
import macros

ins 1
outs 1

struct Ah:
    p float
    
init:
    phase = 0.0
    b array[100, float]
    t = Ah.new(0)
    a = @[1, 2]
    print("Hello")

sample:
    freq_incr = in1 / samplerate
    out1 = sin(phase * 2 * PI)
    phase = (phase + freq_incr) % 1.0