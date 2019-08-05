import macros
import macrosDSP
import math
    
ins 2:
    "freq"
    "phase"

outs 1:
    "audio"

type
    Phasor[T] = object
        phase : T

constructor:
    
    let 
        a = 0
        b = "hello"
        c = sin(0.5)
        d = Phasor[float64](phase : c)

    new a d b c

echo UGenConstructor()[]