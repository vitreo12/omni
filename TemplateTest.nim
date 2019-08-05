import macros
import macrosDSP
import math
    
ins 1:
    "freq"

outs 1:
    "sine_out"

type
    Phasor[T] = object
        p : T

constructor:
    let phasor = Phasor[float64]()
    
    new: phasor

perform:
    var 
        frequency : float
        phase : float
        sine_out : float

    sample:
        phase = phasor.p
        frequency = in1()

        if phase >= 1.0:
            phase = 0.0
        
        sine_out = cos(phase * 2 * PI)
        
        out1() = sine_out

        phase += abs(frequency) / (48000 - 1)

        phasor.p = phase