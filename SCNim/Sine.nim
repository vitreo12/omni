#nim c --app:lib --gc:none --noMain -d:supercollider -d:release -d:danger

import macros
import math
import ../dsp_macros
import ../dsp_print
import ../sc_types

#For rt_alloc/rt_alloc0/rt_realloc/rt_free
import ../RTAlloc/rt_alloc

import ../RTAlloc/sc_data
    
ins 1:
    "freq"

outs 1:
    "sine_out"
 
expandMacros:
    constructor:
        let 
            sampleRate = 48000.0
            #mydata = Data.init(480000)

        var phase = 0.0
        
        new phase, sampleRate#, mydata

perform:
    var 
        frequency : float
        sine_out : float

    sample:
        frequency = in1

        if phase >= 1.0:
            phase = 0.0

        sine_out = cos(phase * 2 * PI) #phase equals to phase_var[]
        
        out1 = sine_out

        phase += abs(frequency) / (sampleRate - 1) #phase equals to phase_var[]