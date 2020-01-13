import macros
import ../../omni

#expandMacros:
struct Phasor:
    phase : float

#expandMacros:
def newPhasor() -> Phasor:
    return Phasor.new(0.0)

ins 1
outs 1

expandMacros:
    init:
        phasor = Phasor.new(0.0)

#expandMacros:
perform:
    increment = in1 / samplerate
    
    sample:
        out1 = phasor.phase
        phasor.phase += increment
        phasor.phase = phasor.phase mod 1.0