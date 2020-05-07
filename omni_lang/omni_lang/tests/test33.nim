import ../../omni_lang
import macros

expandMacros:
    struct Saw:
        phase
        prev_value

    def perform(saw Saw, freq_in = 440.0):
        freq = freq_in
        if freq == 0.0:
            freq = 0.01
        
        #0.0 would result in 0 / 0 -> NaN
        if saw.phase == 0.0:
            saw.phase = 1.0

        #BLIT
        n = trunc((samplerate * 0.5) / freq)
        phase_2pi = saw.phase * 2 * PI
        blit = 0.5 * (sin(phase_2pi * (n + 0.5)) / (sin(phase_2pi * 0.5)) - 1.0)

        #Leaky integrator
        freq_over_samplerate = (freq * 2 * PI) / samplerate * 0.25
        out_value = (freq_over_samplerate * (blit - saw.prev_value)) + saw.prev_value
        
        #Update entries in struct
        saw.phase = ((saw.phase + freq) / (samplerate - 1)) % 1.0
        saw.prev_value = out_value

        return out_value

    init:
        saw = Saw()

    sample:
        out1 = saw.perform()