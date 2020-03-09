import macros
import ../../omni_lang

ins 1:
    "freq"

outs 1

expandMacros:
    init:
        phase = 0.0
        prev_value = 0.0
        samplerate_minus_one = get_samplerate - 1.0

        print("hello")

def twoPi():
    return 2.0 * PI

perform:
    sample:
        freq = abs(in1)
        if freq == 0.0:
            freq = 0.01
        
        #0.0 would result in 0 / 0 -> NaN
        if phase == 0.0:
            phase = 1.0

        #BLIT
        n = trunc((get_samplerate * 0.5) / freq)
        phase_2pi = phase * twoPi()
        blit = 0.5 * (sin(phase_2pi * (n + 0.5)) / (sin(phase_2pi * 0.5)) - 1.0)

        #Leaky integrator
        freq_over_samplerate = (freq * twoPi()) / get_samplerate * 0.25
        out_value = (freq_over_samplerate * (blit - prev_value)) + prev_value
        
        out1 = out_value
        
        phase += freq / samplerate_minus_one
        phase = phase mod 1.0
        prev_value = out_value