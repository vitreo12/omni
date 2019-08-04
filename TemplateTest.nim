from macros import expandMacros
import macrosDSP
    
inputs 2:
    "freq"
    "phase"

outputs 1:
    "audio"

type
    Phasor[T] = object
        phase : T

constructor:

    #This would throw error: non initialized variable
    var h : int

    let 
        a = 0
        b = "hello"
        c = 0.5
        d = Phasor[float64](phase : c)
    
    new a, b, d 